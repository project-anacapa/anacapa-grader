class Machine
  def initialize(host,account,privatekey)
    @host = host,
    @account = account
    @privatekey = privatekey
  end
  #todo add multiple machines
  def get_unused_machine()
    Machine.new(ENV['WORKER_HOST'],ENV['WORKER_ACCOUNT'],ENV['WORKER_PRIVATE_KEY'])
  end
end
