class WorkerMachine
  def initialize(host,user,port,private_key)
    @host = host
    @user = user
    @port = port
    @private_key = private_key
  end
  attr_reader :host
  attr_reader :user
  attr_reader :port
  attr_reader :private_key

  #todo add multiple machines
  def self.get_idle_machine()
    WorkerMachine.new(ENV['WORKER_HOST'],ENV['WORKER_USER'],ENV['WORKER_PORT'],ENV['WORKER_PRIVATE_KEY'])
  end
end
