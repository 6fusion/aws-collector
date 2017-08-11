module KubernetesHelper

  def self.save_value(key, value)
    begin
      config_map = get_config_map
      config_map.data[key] = value
      $kube_client.update_config_map config_map
      value
    rescue KubeException => e
      Rails.logger.error { e }
      Rails.logger.debug { e.backtrace[0..15].join("\n") }
      raise e
    end
  end

  def self.get_value(key)
    begin
      config_map = get_config_map
      config_map.data[key]
    rescue KubeException => e
      if e.error_code == 404
        nil
      else
        Rails.logger.error { e }
        Rails.logger.debug { e.backtrace[0..15].join("\n") }
        raise e
      end
    end
  end

  private
  def self.get_config_map
    begin
      $kubernetes_client.get_config_map('aws-collector-configmap', namespace)
    rescue KubeException => e
      Rails.logger.debug { e.backtrace[0..15].join("\n") } unless e.error_code == 404
      config_map = Kubeclient::ConfigMap.new
      config_map.metadata = { name: name,
                              namespace: namespace }
      config_map.data = {}
      $kubernetes_client.create_config_map config_map
    end
  end

  def self.namespace
    @namespace ||= File.read('/var/run/secrets/kubernetes.io/serviceaccount/namespace')
  end

  def self.client
    @kubernetes_client ||=
      begin
        auth_options = { bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token' }
        ssl_options = { ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
                        verify_ssl: OpenSSL::SSL::VERIFY_PEER }
        host, port = ENV['KUBERNETES_PORT'].match(%r|.+://(.+):(\d+)|)[1..2]
        Kubeclient::Client.new "https://#{host}:#{port}/api", 'v1',
                               auth_options: auth_options,
                               ssl_options: ssl_options
      end
  end

end



