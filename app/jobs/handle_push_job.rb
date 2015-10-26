require 'net/ssh'
require 'net/scp'


class HandlePushJob < ActiveJob::Base
  queue_as :default

  def perform(url, version, grader_url, grader_version)
    Dir.mktmpdir do |dir|
      # use the directory...
      clone_revision(url,version,dir)
      clone_grader(grader_url, grader_version, dir)

      #Right now we only support one worker
      machine = WorkerMachine.get_idle_machine()

      Net::SSH.start(machine.host, machine.user,
                     :port => machine.port,
                     :keys => [],
                     :key_data => [machine.private_key],
                     :keys_only => TRUE
                     ) do |ssh|
        killall_processes(ssh)
        copy_workspace(machine,dir)
        process_testables(ssh,dir)
      end

    end
  end

  def clone_grader(url,version,dir)
    g = Git.clone(url, 'grader', :path => dir)
    g.checkout(version)
  end

  def clone_revision(url,version,dir)
    g = Git.clone(url, 'student', :path => dir)
    g.checkout(version)
  end

  def killall_processes(ssh)
    #killall processes execpt those returned by
    # ps T selects all processes and threads that belong to the current terminal
    # -N negates it
    ssh.exec!("kill -9 `ps -o pid= -N T`")
  end

  def process_testables(ssh, dir)
    testables_dir = "#{dir}/grader/testables"
    results_dir   = "#{dir}/results"

    create_expected_workspace(ssh)

    build_testables(ssh,testablesdir)

    Dir.foreach(testablesdir) do |file|
      if File.directory?(file)
        generate_expected(ssh,file)
      end
    end

    create_student_workspace(ssh)

    build_testables(ssh,testablesdir)

    #Remove the solutions and the build files. We are going to run untrusted code.
    remove_instructor_files();

    Dir.foreach(testablesdir) do |file|
      if File.directory?(file)
        do_testable(ssh,file,results_dir)
      end
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

    Net::SCP.upload!(machine.host, machine.user,
        "#{dir}/student", ".",
        :recursive => TRUE,
        :ssh => ssh)
  end

  def create_expected_workspace(ssh,dir)
    ssh.exec!('mkdir ~/workspace')
    #assume we use all student files
    ssh.exec!('cp ~/grader/student_files/* ~/workspace')
    #assume we use all instructor files
    ssh.exec!('cp ~/grader/instructor_files/* ~/workspace')
    #create an executables directory
    ssh.exec!('mkdir ~/executables')
  end

  def clear_workspace()
    ssh.exec!('rm -rf ~/workspace ~/executables')
  end

  def create_student_workspace(ssh,dir)
    ssh.exec!('mkdir ~/workspace')
    #assume we use all student files
    ssh.exec!('cp ~/student ~/workspace')
    #assume we use all instructor files
    ssh.exec!('cp ~/grader/instructor_files/* ~/workspace')
    #create an executables directory
    ssh.exec!('mkdir ~/executables')
  end


  #If a expected file doesn't exist generate one
  def generate_expected(ssh,dir)
    Dir.foreach(dir) do |file|
      if File.directory?(file)
        expected_filename = "#{file}/expected_file"
        if not File.exists?(expected_file)
          run_testcase(ssh,file,expected_filename)
        end
      end
    end
  end

  #Put the results into an output directory
  def do_testable(ssh,dir,results_dir)
    testable_name = File.basename(file)
    Dir.foreach(dir) do |file|
      if File.directory?(file)
        output_filename = "#{results_dir}/#{testable_name}/#{testcase_name}"
        run_testcase(ssh, file, output_filename)
      end
    end
  end

  #Student code should never read the grader files
  def remove_instructor_files(ssh)
    ssh.exec('rm -rf ~/grader')
  end


  def build_testables(testablesdir)
    Dir.foreach(testablesdir) do |file|
      if File.directory?(file)
        build_testable(ssh,file)
        copy_to_executables(ssh,file)
      end
    end
  end

  def copy_to_executables(ssh,dir)
    executable_filename = File.basename(dir)
    ssh.exec!("cp ~/workspace/#{executable_filename} ~/executables/#{executable_filename}")
  end

  def build_testable(ssh,dir)
    executable_filename = File.basename(dir)
    #we need to figure out which rule to invoke from dir
    ssh.exec!("make -C ~/workspace #{executable_filename}")
  end

  def run_testcase(ssh,dir,output_file)
    testcase_name = File.basename(dir)
    File.open(output_file, 'w') do |output|
      ssh.exec!("~/executables/#{testcase_name}") do |channel, stream, data|
        output << data if stream == :stdout
      end
    end
  end
end
