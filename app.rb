require 'sinatra/base'

class ActivityPub < Sinatra::Application
  @my_routes =
    [
      [:get, '/.well-known/host-meta/?', HostMetaRoute],
      [:get, '/.well-known/webfinger/?', WebfingerRoute],
      [:get, '/users/:username/outbox/?', OutboxRoute],
      [:post, '/users/:username/inbox/?', InboxRoute],
      [:get, '/users/:username/?', AccountRoute],
      [:get, '/users/:username/followers/?', FollowersRoute],
      [:get, '/users/:username/following/?', FollowingRoute],
      [:get, '/users/:username/collections/:id/?', CollectionRoute],
      [:get, '/users/:username/statuses/:id/?', StatusRoute],
      [:get, '/search', SearchRoute],

      [:get, '/api/v1/statuses', ReadStatusesRoute],
      [:get, '/api/v1/notifications', ReadNotificationsRoute],
      [:post, '/api/v1/follows', CreateFollowRoute],
      [:delete, '/api/v1/follows', DestroyFollowRoute],
      [:post, '/api/v1/favorites', CreateFavoriteRoute],
      [:delete, '/api/v1/favorites', DestroyFavoriteRoute],
      [:post, '/api/v1/reblogs', CreateReblogRoute],
      [:delete, '/api/v1/reblogs', DestroyReblogRoute],
      [:post, '/api/v1/statuses', CreateStatusRoute],
      [:delete, '/api/v1/statuses', DestroyStatusRoute]
    ]

  @my_routes.each do |meth, path, klass|
    send(meth, path) do
      formatted_request =
        request.tap do |req|
          req.params.merge!(params)
          headers =
            req
            .env
            .keys
            .select { |k| k.start_with?('HTTP_') }
            .each_with_object({}) do |key, hash|
              header_name =
                key
                  .downcase
                  .sub(/^http_./) { |foo| foo[-1].upcase }
                  .gsub(/_./) { |foo| "-#{foo[1].upcase}" }

              hash[header_name] = req.env[key]
            end

          headers['Content-Type'] = req.env['CONTENT_TYPE']

          req['headers'] = headers
        end

      klass.call(formatted_request)
    end
  end
end
