require 'net/ssh'
require 'net/scp'


class HandlePushJob < ActiveJob::Base
  queue_as :default

  def perform(url, version, grader_url, results_url)
    Rails.application.config.logger.info "Begin student processing"
    Dir.mktmpdir do |dir|
      # use the directory...
      Rails.application.config.logger.info "Clone revision"

      Rails.application.config.logger.info "Clone student"
      clone_revision(url,version,dir,"student")
      Rails.application.config.logger.info "Clone grader"
      clone(grader_url, dir,"grader")
      Rails.application.config.logger.info "Clone results"
      git_results  = clone(results_url, dir,"results")
      begin
        git_results.remove('.',{:recursive =>  TRUE})
      rescue
      end

      #Right now we only support one worker
      machine = WorkerMachine.get_idle_machine()
      logger = Logger.new(STDOUT)
      Net::SSH.start(machine.host, machine.user,
                     :port => machine.port,
                     :keys => [],
                     :key_data => [machine.private_key],
                     :keys_only => TRUE
                     ) do |ssh|
        logger.info 'killall'
        killall_processes(ssh)
        clear_all(ssh)
        copy_workspace(machine,dir)
        process_testables(ssh,dir)
      end
      push(git_results)

    end
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
      #commit throws an exception if there is nothing to commit
    end
  end

  def clone_revision(url,version,dir,name)
    g = Git.clone(url, name, :path => dir)
    g.checkout(version)
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
    testables_path = "#{dir}/grader/testables"
    results_path   = "#{dir}/results/"

    create_student_workspace(ssh)
    build_testables(ssh,testables_path,results_path)

    #Remove the solutions and the build files. We are going to run untrusted code.
    remove_instructor_files(ssh);

    Dir.foreach(testables_path) do |file|
      next if file == '.' || file == '..'
      testable_path = "#{testables_path}/#{file}"
      if File.directory?(testable_path)
        do_testable(ssh,testable_path,results_path)
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
        "#{dir}/student", ".",
        :recursive => TRUE,
        :ssh => ssh)
  end

  def create_student_workspace(ssh)
    ssh.exec!('mkdir ~/workspace')
    #assume we use all student files
    ssh.exec!('cp -r ~/student/* ~/workspace')
    #assume we use all instructor files
    ssh.exec!('cp -r ~/instructor_files/* ~/workspace')
    #create an executables directory
    ssh.exec!('mkdir ~/executables')
  end

  #Put the results into an output directory
  def do_testable(ssh,testable_path,results_path)
    testable_name = File.basename(testable_path)
    Dir.foreach(testable_path) do |file|
      next if file == '.' || file == '..'
      testcase_name = file
      testcase_path = "#{testable_path}/#{file}"
      if File.directory?(testcase_path)

        output_filename = "#{results_path}/#{testable_name}/#{testcase_name}"
        run_testcase(ssh, testcase_path, output_filename)
      end
    end
  end

  #Student code should never read the grader files
  def remove_instructor_files(ssh)
    #ssh.exec!('rm -rf ~/instructor_files ~/student_files ~/student ~/workspace')
  end


  def build_testables(ssh,testables_dir,results_path)
    Dir.foreach(testables_dir) do |file|
      next if file == '.' || file == '..'
      testable_dir = "#{testables_dir}/#{file}"
      testable_name = file
      output_filename = "#{results_path}/#{testable_name}/build_results"
      FileUtils.mkdir_p("#{results_path}/#{testable_name}")
      if File.directory?(testable_dir)
        build_testable(ssh,testable_dir,output_filename)
      end
    end
  end

  def copy_to_executables(ssh,executable_filename)
    logger = Logger.new(STDOUT)
    logger.info "cp ~/workspace/#{executable_filename} ~/executables/#{executable_filename}"
    logger.info ssh.exec!("cp ~/workspace/#{executable_filename} ~/executables/#{executable_filename}")
  end

  def build_testable(ssh,dir,output_file)
    executable_filename = File.basename(dir)
    logger = Logger.new(STDOUT)
    logger.info executable_filename

    make_output = ""
    exit_code = nil
    exit_signal = nil

    command = "make -C ~/workspace #{executable_filename}"
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
        channel.wait()
      end
      #ssh.loop
      logger.info make_output


      if(exit_code != 0)
        File.open(output_file, 'wb') do |output|
          output << make_output
        end
      else
        copy_to_executables(ssh,executable_filename)
      end
    end

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
