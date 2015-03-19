class RedisUniqueQueue
  constructor: (name, options) ->
    @name      = name
    @redis     = options.redis     || connectToRedis options
    @namespace = options.namespace || 'resque'
    @timeout   = options.timeout   || 5000
    @redis.select options.database if options.database?


  push: (data, callback)->
    score = @current_time()
    @redis.zadd(@name, score, data, callback)

  pop: (callback)->
    console.log "in pop"
    that = this
    timeout = ->
      console.log "made to timeout"
      that.attempt_atomic_pop (err, reply, commit_success)->
        console.log "commit success is #{commit_success}"
        if !commit_success
          console.log "atomic pop failed so trying again..."
          that.pop callback
        else
          callback err, reply[0]
    setTimeout timeout, 1000

  front: (callback)->
    @redis.zrange(@name, 0, 0, callback)

  remove: (data, callback)->
    @redis.zrem @name, data, callback

  size: (callback)->
    console.log "getting size for #{@name}"
    @redis.zcard @name, callback

  all: (callback)->
    that = this
    @size (err, size)->
      if err
        callback err, null
      else
        that.peek 0, size, callback

  peek: (index, amount, callback)->
    @redis.zrange @name, index, index + amount - 1, callback

  include: (data, callback)->
    @redis.zscore @name, data, (err, reply)->
      callback( err, reply != null)

  clear: (callback)->
    @redis.del @name, callback

  current_time: ->
    new Date().valueOf()

  attempt_atomic_pop: (callback)->
    min_score = 0
    max_score = @current_time()

    redis = @redis
    name = @name

    result  = null
    @redis.watch @name, (watch_err, watch_reply)->
      console.log "watch err is #{watch_err} and watch_reply is #{JSON.stringify watch_reply}"
      redis.zrangebyscore name, min_score, max_score, 'limit', 0, 1, (zrangebyscore_err, item_to_remove)->
        console.log "zrangebyscorreerr is #{zrangebyscore_err} and item to remove is #{JSON.stringify item_to_remove}"
        if item_to_remove.length > 0
          if zrangebyscore_err == null
            redis.multi().zrem(name, item_to_remove).exec (exec_err, exec_replies)->
              console.log "exec err is #{exec_err} and replies is #{JSON.stringify exec_replies}"
              callback exec_err, item_to_remove, exec_replies && (exec_replies.reduce (t, s) -> t + s) > 0
          else
            callback zrangebyscore_err, item_to_remove, false
        else
          callback zrangebyscore_err, [null], true

  connectToRedis = (options) ->
    redis = require('redis').createClient options.port, options.host
    redis.auth options.password if options.password?
    redis



module.exports = RedisUniqueQueue
