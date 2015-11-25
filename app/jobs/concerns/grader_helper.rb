module GraderHelper

  def generate_results (dir)
    machine = WorkerMachine.get_idle_machine()
    testables = nil
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
      testables = process_testables(ssh,dir)
    end
    testables
  end

  def copy_workspace(machine,dir)
    ssh = {:port => machine.port,
           :key_data => machine.private_key }

    Net::SCP.upload!(machine.host, machine.user,
      "#{dir}/grader/instructor_files", ".",
      :recursive => TRUE,
      :ssh => ssh)
    Net::SCP.upload!(machine.host, machine.user,
      "#{dir}/student", "student_files",
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

  def process_testables(ssh, dir)
    testable_json = "#{dir}/grader/testables.json"
    testables = JSON.parse(File.read(testable_json))

    create_workspace(ssh)
    testables["testables"].each do |testable|
      testable["make_output"] = build_testable(ssh,testable["make_target"])
      if(testable["make_output"]["exit_code"] == 0)
        copy_to_executables(ssh,testable["make_target"])
      end
    end
    remove_instructor_files(ssh);

    testables["testables"].each do |testable|
      if(testable["make_output"]["exit_code"] == 0)
        testable["test_cases"].each do |test_case|
          test_case["output"] = run_testcase(ssh, test_case["command"],
                                            test_case["diff_input"].to_sym)
          end
      end
    end
    testables
  end

  def create_workspace(ssh)
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

  def clone_revision(url,version,dir,name)
    g = Git.clone(url, name, :path => dir)
    g.checkout(version)
  end

  def push(g)
    g.add(:all=>true)
    begin
      g.commit('grader', {:author=> "AnacapaBot <hunterlaux+anacapabot@gmail.com>"})
      g.push
    rescue
    end
  end

  def copy_to_executables(ssh,executable_filename)
    ssh.exec!("cp ~/workspace/#{executable_filename} ~/executables/#{executable_filename}")
  end

  def build_testable(ssh,make_target)
    make_output = ""
    exit_code = nil
    exit_signal = nil
    command = "make -C ~/workspace #{make_target}"
    ssh.open_channel do |channel|
      channel.exec(command) do |ch, success|
        unless success
          abort "FAILED: couldn't execute command (ssh.channel.exec)"
        end
        channel.on_data do |ch,data|
          make_output +=data
        end
        channel.on_extended_data do |ch,type,data|
          make_output +=data
        end
        channel.on_request("exit-status") do |ch,data|
          exit_code = data.read_long
        end
        channel.on_request("exit-signal") do |ch, data|
          exit_signal = data.read_long
        end
      end
    end
    {
     "make_output" => make_output,
     "exit_code"   => exit_code
    }
  end

  def run_testcase(ssh, test_command, output_channel)
    output = ""
    ssh.exec!("cd ~/executables && #{test_command}") do |channel, stream, data|
      output+= data if stream == output_channel
    end
    output
  end

  def remove_instructor_files(ssh)
    ssh.exec!('rm -rf ~/instructor_files ~/student_files ~/student ~/workspace')
  end
end
