require 'net/ssh'
require 'net/scp'

class GenerateExpectedJob < ActiveJob::Base
  queue_as :default

  def perform(grader_url, expected_url)
    Dir.mktmpdir do |dir|
      # use the directory...
      clone(grader_url, dir, "grader")
      git_expected = clone(expected_url, dir,"expected")
      begin
        git_expected.remove('.',{:recursive =>  TRUE})
      rescue
      end
      #Right now we only support one worker
      machine = WorkerMachine.get_idle_machine()

      Rails.application.config.logger.info "SSH machine #{machine.host}, #{machine.private_key}, #{machine.port}, #{machine.user}"
      Net::SSH.start(machine.host, machine.user,
                     :port => machine.port,
                     :keys => [],
                     :key_data => [machine.private_key],
                     :keys_only => TRUE
                     ) do |ssh|
        killall_processes(ssh)
        clear_all(ssh)
        copy_workspace(machine,dir)
        process_testables(ssh,dir)
      end
      push(git_expected)
    end
  end

  def copy_workspace(machine,dir)
      ssh = {:port => machine.port,
             :key_data => machine.private_key }

      Net::SCP.upload!(machine.host, machine.user,
        "#{dir}/grader/instructor_files", ".",
        :recursive => TRUE,
        :ssh => ssh)
      Net::SCP.upload!(machine.host, machine.user,
          "#{dir}/grader/student_files", ".",
          :recursive => TRUE,
          :ssh => ssh)
  end


  def killall_processes(ssh)
    #killall processes execpt those returned by
    # ps T selects all processes and threads that belong to the current terminal
    # -N negates it
    ssh.exec!("kill -9 `ps -o pid= -N T`")
  end


  def clear_all(ssh)
    ssh.exec!("rm -rf ~/instructor_files ~/student_files ~/student ~/workspace ~/executables")
  end

  def copy_expected(dir)
    FileUtils.cp_r "#{dir}/grader/testables", "#{dir}/expected/"
  end


  def process_testables(ssh, dir)
    testable_json = "#{dir}/grader/testables.json"
    testables = JSON.parse(File.read(testable_json))

    create_expected_workspace(ssh)

    testables["testables"].each do |testable|
      build_testable(ssh,testable["make_target"])
      copy_to_executables(ssh,testable["make_target"])
    end

    testables["testables"].each do |testable|
      testable["test_cases"].each do |test_case|
        test_case["output"] = run_testcase(ssh, test_case["command"],
                                           test_case["diff_input"].to_sym)
        end
    end

    output_filename = "#{dir}/expected/expected.json"
    File.open(output_filename, "w") do |file|
      file << JSON.pretty_generate(testables)
    end

  end

  def create_expected_workspace(ssh)
    ssh.exec!('mkdir ~/workspace')
    #assume we use all student files
    ssh.exec!('cp -r ~/student_files/* ~/workspace')
    #assume we use all instructor files
    ssh.exec!('cp -r ~/instructor_files/* ~/workspace')
    #create an executables directory
    ssh.exec!('mkdir ~/executables')
  end

  def clone(url,dir,name)
    Git.clone(url, name, :path => dir)
  end

  def push(g)
    g.add(:all=>true)
    begin
      g.commit('grader', {:author=> "AnacapaBot <hunterlaux+anacapabot@gmail.com>"})
      g.push
    rescue
    end
  end

  def copy_to_executables(ssh,dir)
    executable_filename = File.basename(dir)
    ssh.exec!("cp ~/workspace/#{executable_filename} ~/executables/#{executable_filename}")
  end

  def build_testable(ssh,make_target)
    #we need to figure out which rule to invoke from dir
    output = ssh.exec!("make -C ~/workspace #{make_target}")
    Rails.application.config.logger.info "BUILD RESULTS #{output}"
  end

  def run_testcase(ssh, test_command, output_channel)
    output = ""
    ssh.exec!("cd ~/executables && #{test_command}") do |channel, stream, data|
      output+= data if stream == output_channel
    end
    output
  end
end
