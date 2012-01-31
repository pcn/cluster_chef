module ClusterChef
  module Cloud
    # Right now there is no support for interacting with storage for
    # deployment.  In cluster_chef there is a clear separation between
    # what happens on the server vs. the client.  However, with aws
    # there's a desire to remove access of actually usable aws keys
    # from instances.  
    #
    # However, deploying software from S3 to a host can be done
    # without keys and without making the repo public via a hash
    # function of the path to the file, the key, and an expiration
    # time.  Supporting this is easy, and creates a better way of 
    # doing deployment.
    #
    # To support this, provide an explicit aws_access_key_id and
    # aws_secret_access_key in the knife.rb, in the knife hash.  This
    # allows uploading to a bucket owned by another account without
    # using IAMs (arguably not always the right way to go, but it is
    # useful and doesn't do any harm).
    
    class S3 < Base

      # Takes a filename (which may or may not exist) and the bucket
      # it lives in, and optionally an expiration time (defaults to 2
      # hours, specified as # of seconds)
      # @returns [Hash] of :name and :url.  url is time-limited.
      def self.expiring_url(name, bucket, expires=nil)
        expires ||= Time.now() + (60 * 60 * 2)
        knife = Chef::Config[:knife]
        s3con = Fog::Storage.new({
                                   :provider =>'AWS',
                                   :aws_access_key_id => knife[:aws_access_key_id],
                                   :aws_secret_access_key => knife[:aws_secret_access_key] 
                                 })
        url = s3con.get_object_https_url(bucket, name, expires)
        return {:name => name, :url => url}
      end
    end
  end
end
