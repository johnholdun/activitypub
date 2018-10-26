class CreateReblogRoute < Route
  def call
    # TODO: authentication
    account_id = "#{BASE_URL}/users/john"

    request.body.rewind
    body = request.body.read.force_encoding('UTF-8')
    json = Oj.load(body, mode: :strict)
    status_uri = json['statusUri']

    headers['Content-Type'] = 'application/json'

    begin
      ReblogCreator.call \
        account_uri: account_id,
        status_uri: status_uri

      finish_json \
        data: {
          type: 'reblogs',
          accountId: account_id,
          statusUri: status_uri
        }
    rescue => e
      finish_json(errors: [e.to_s], status: 500)
    end
  end
end
