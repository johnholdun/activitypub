require './lib/service'

class FollowAccepter < Service
  attribute :account_id
  attribute :item

  def call
    account = STORAGE.read(:accounts, account_id)
    follower = STORAGE.read(:accounts, item['actor'])

    Deliverer.call \
      account,
      [follower['inbox']],
      id: nil,
      type: 'Accept',
      actor: account['id'],
      object: item
  end
end
