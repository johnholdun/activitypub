class WebfingerRoute < Route
  def call
    resource = request.params['resource']

    uri =
      case resource
      when /\A#{BASE_URL}/i
        resource
      when /\@/
        username, domain = resource.gsub(/\Aacct:/, '').split('@', 2)

        if domain.gsub(/\//, '').casecmp(LOCAL_DOMAIN).zero?
          "#{BASE_URL}/users/#{username}"
        end
      end

    return not_found unless uri

    @account = DB[:actors].where(id: uri).first

    return not_found unless @account

    @account = Oj.load(@account[:json])

    headers['Vary'] = 'Accept'
    headers['Content-Type'] = 'application/jrd+json'
    headers['Cache-Control'] = 'max-age=259200, public'

    finish_json \
      subject: "acct:#{@account['preferredUsername']}@#{LOCAL_DOMAIN}",
      aliases: [@account['id']],
      links: [
        {
          rel: 'self',
          type: 'application/activity+json',
          href: @account['id']
        },
        {
          rel: 'magic-public-key',
          href: "data:application/magic-public-key,#{magic_key}"
        }
      ]
  end

  private

  def uri
    @uri ||= "acct:#{@account['preferredUsername']}@#{LOCAL_DOMAIN}"
  end

  def private_key
    actor = DB[:actors].where(id: @account['id']).first
    actor[:private_key] if actor
  end

  def public_key
    @account['publicKey']['publicKeyPem']
  end

  def magic_key
    keypair = OpenSSL::PKey::RSA.new(private_key || public_key)

    modulus, exponent =
      [keypair.public_key.n, keypair.public_key.e].map do |component|
        result = []

        until component.zero?
          result << [component % 256].pack('C')
          component >>= 8
        end

        result.reverse.join
      end

    "RSA.#{Base64.urlsafe_encode64 modulus}.#{Base64.urlsafe_encode64 exponent}"
  end
end
