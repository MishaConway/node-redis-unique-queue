

options = {}
options.namespace ||= 'coffee-redis-resque-queue-test'
options.port = 6379


QueueClass = require '../src/index.coffee'

console.log "got here"
console.log "queueclass is #{QueueClass}"

queue = new QueueClass('lala', options)


add_items = (queue, items, callback)->
  item = items.pop()
  queue.push item, (err, reply)->
    if items.length > 0
      add_items(queue, items, callback)
    else
      callback(queue)

pop_items = (queue, result, callback)->
  queue.pop (err, item)->
    console.log "popped #{item}"
    if item
      result.push item
    queue.size (err, size)->
      console.log "after pop size is #{size}"
      if size > 0
        queue.all (err, data)->
          console.log "full data is #{JSON.stringify data}"
          pop_items(queue, result, callback)
      else
        callback(result)



queue.clear (err, reply)->
  console.log "reply on clear is #{reply}"
  add_items queue, [1,2,3,4,5,6,7,8,9,10].reverse(), (queue)->
    queue.size (err, size) ->
      console.log "queue size is: #{size}"

      queue.push 123, (err, result)->
        console.log "result from push is #{result}"
        queue.size (err, size)->
          console.log "queue size is now #{size}"
          queue.front (err, f)->
            console.log "front is #{f}"
            pop_items queue, [], (result)->
              console.log "result after popping all items is #{JSON.stringify result}"
            pop_items queue, [], (result)->
              console.log "result after popping all items is #{JSON.stringify result}"
            add_items queue, [1,2,3,4,5,6,7,8,9,10].reverse(), ->
            add_items queue, [1,2,3,4,5,6,7,8,9,10].reverse(), ->
            add_items queue, [1,2,3,4,5,6,7,8,9,10].reverse(), ->





