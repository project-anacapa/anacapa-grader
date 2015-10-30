require 'net/ssh'
require 'net/scp'

class GenerateExpectedJob < ActiveJob::Base
  queue_as :default

  def perform(grader_url, expected_url)
    Dir.mktmpdir do |dir|
      # use the directory...
      clone(grader_url, dir, "grader")
      git_expected = clone(expected_url, dir,"expected")

      clear_expected(dir)

      #Right now we only support one worker
      machine = WorkerMachine.get_idle_machine()

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
        copy_expected(dir)
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

  def clear_expected(dir)
    FileUtils.rm_rf("#{dir}/expected/*")
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
    testables_path = "#{dir}/grader/testables"
    expected_path = "#{dir}/expected"
    Dir.foreach(testables_path) do |file|
      next if file == '.' || file == '..'
      testable_path = "#{testables_path}/#{file}"
      testable_name = file
      if File.directory?(testable_path)
        Dir.foreach(testables_path) do |file|
          next if file == '.' || file == '..'
          testcase_path = "#{testable_path}/#{file}"
          testcase_name = file
          if File.directory?(testcase_path)
            if File.directory?(testable_path)
              FileUtils.mkdir_p("#{expected_path}/#{testable_name}")
              FileUtils.cp("#{testcase_path}/expected_file",
                "#{expected_path}/#{testable_name}/#{testcase_name}")
            end
          end
        end
      end
    end
  end


  def process_testables(ssh, dir)
    testables_path = "#{dir}/grader/testables"
    create_expected_workspace(ssh)
    build_testables(ssh,testables_path)
    Dir.foreach(testables_path) do |file|
    next if file == '.' || file == '..'
      testable_path = "#{testables_path}/#{file}"
      if File.directory?(testable_path)
        generate_expected(ssh,testable_path)
      end
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

  #If a expected file doesn't exist generate one
  def generate_expected(ssh,testable_path)
    Dir.foreach(testable_path) do |file|
      next if file == '.' || file == '..'
      testcase_path = "#{testable_path}/#{file}"
      if File.directory?(testcase_path)
        expected_filename = "#{testcase_path}/expected_file"
        if not File.exists?(expected_filename)
          run_testcase(ssh,testcase_path,expected_filename)
        end
      end
    end
  end

  def clone(url,dir,name)
    Git.clone(url, name, :path => dir)
  end

  def push(g)
    g.add(:all=>true)
    begin
      g.commit('grader')
      g.push
    rescue
    end
  end

  def build_testables(ssh,testables_dir)
    Dir.foreach(testables_dir) do |file|
      next if file == '.' || file == '..'
      testable_dir = "#{testables_dir}/#{file}"
      if File.directory?(testable_dir)
        build_testable(ssh,testable_dir)
        copy_to_executables(ssh,testable_dir)
      end
    end
  end

  def copy_to_executables(ssh,dir)
    executable_filename = File.basename(dir)
    ssh.exec!("cp ~/workspace/#{executable_filename} ~/executables/#{executable_filename}")
  end

  def build_testable(ssh,dir)
    executable_filename = File.basename(dir)
    logger = Logger.new(STDOUT)
    logger.info executable_filename
    #we need to figure out which rule to invoke from dir
    ssh.exec!("make -C ~/workspace #{executable_filename}")
  end
  def run_testcase(ssh,dir,output_file)
    testcase_name = File.basename(dir)
    File.open(output_file, 'w') do |output|
      ssh.exec!("cd ~/executables && ./#{testcase_name}") do |channel, stream, data|
        output << data if stream == :stdout
      end
    end
  end
end
