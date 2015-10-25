

class HandlePushJob < ActiveJob::Base
  queue_as :default

  def perform(url, version, grader_url, grader_version)
    Dir.mktmpdir do |dir|
      # use the directory...
      clone_revision(url,version,dir)
      clone_grader(grader_url, grader_version, dir)

      #Right now we only support one worker
      machine = Machine.get_unused_machine()

      Net::SSH.start(machine.host, machine.user, :key_data => machine.privatekey) do |ssh|
        killall_processes(ssh)
        rsync_workspace(machine,dir)
        run_testcases(ssh,dir)
        rsync_back_results(machine,dir)
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
    ssh.exec("kill -9 `ps -o pid= -N T`")
  end

  def do_testables(ssh, dir)
    testablesdir = "#{dir}/grader/testables"
    Dir.foreach(testablesdir) do |file|
      if File.directory?(file)
        generate_expected(file)
      end
    end

    #Remove the solutions because now we are going to run untrusted code
    remove_grader_student_directory();

    Dir.foreach(testablesdir) do |file|
      if File.directory?(file)
        do_testable(file)
      end
    end
  end

  def remove_grader_student_directory(ssh)
    ssh.exec('rm -rf ~/grader/student_files')
  end

  def generate_expected(ssh,dir)

  end

  def do_testable(machine,dir)
    build_testable(dir)
    Dir.foreach(dir) do |file|
      if File.directory?(file)
        run_testcase(file)
      end
    end
  end

  def copy_workspace(machine,dir)
    Net::SCP.upload!(machine.host, machine.user,
      "#{dir}/grader/instructor_files", "~/grader/instructor_files",
      :ssh => { :key_data = machine.key_data })

  end

  def build_testable(machine,dir)

  end

  def run_testable(machine,dir)

  end

end
