import std/[strformat]
import std/[tables]

type
  Node[K, V] = ref object
    key: K
    value: V
    prev: Node[K, V]
    next: Node[K, V]
    visited: bool

type
  Cache*[K, V] = ref object
    head: Node[K, V]
    tail: Node[K, V]
    cursor: Node[K, V]
    len: int = 0
    cap: int
    store: TableRef[K, Node[K, V]]

proc delNodeFromStore[K, V](cache: Cache[K, V], node: Node[K, V]) =
  cache.store.del node.key

proc addNodeToStore[K, V](cache: Cache[K, V], node: sink Node[K, V]) =
  cache.store[node.key] = node

proc getNodeFromStore[K, V](cache: Cache[K, V], k: K): Node[K, V] =
  result = cache.store[k]

proc hasNodeInStore[K, V](cache: Cache[K, V], k: K): bool =
  result = cache.store.hasKey(k)

proc delNode[K, V](cache: Cache[K, V], node: Node[K, V]) =
  ## delete the node from linked-list of the cache
  if cache.head == nil:
    return

  if node == cache.head:
    cache.head = node.next
    if node.next != nil:
      node.next.prev = nil
  elif node == cache.tail:
    cache.tail = node.prev
    if node.prev != nil:
      node.prev.next = nil
  else:
    node.prev.next = node.next
    node.next.prev = node.prev

  if cache.cursor == node:
    cache.cursor =
      if node.prev == nil:
        cache.tail
      else:
        node.prev

  node.prev = nil
  node.next = nil
  dec cache.len

proc evit[K, V](cache: Cache[K, V]): Node[K, V] =
  var cursor = cache.cursor
  while true:
    assert cursor != nil
    if cursor.visited:
      cursor.visited = false
      cursor = cursor.prev
      if cursor == nil:
        cursor = cache.tail
    else:
      result = cursor
      cache.cursor = cursor
      cache.delNodeFromStore(cursor)
      cache.delNode(cursor)
      break

proc addNode[K, V](cache: Cache[K, V], node: Node[K, V]) =
  if cache.head == nil:
    cache.head = node
    cache.tail = node
    cache.cursor = node
  else:
    if cache.isFull():
      discard cache.evit()
    let head = cache.head
    head.prev = node
    node.next = head
    cache.head = node
  inc cache.len

# ------ PUBLIC API --------------------

proc `$`*[K, V](node: Node[K, V]): string =
  result = fmt"Node(key={node.key},value={node.value},visited={node.visited})"

proc `$`*[K, V](cache: Cache[K, V]): string =
  result =
    fmt"Cache(len={cache.len},cap={cache.cap},head={cache.head},tail={cache.tail},cursor={cache.cursor})"

proc newCache*[K, V](cap: int): Cache[K, V] =
  if cap < 1:
    raise newException(ValueError, "cap must be > 0")
  result = Cache[K, V](cap: cap, store: newTable[K, Node[K, V]](cap))

proc isFull*[K, V](cache: Cache[K, V]): bool =
  result = cache.len == cache.cap

proc len*[K, V](cache: Cache[K, V]): int =
  result = cache.len

proc cap*[K, V](cache: Cache[K, V]): int =
  result = cache.cap

proc has*[K, V](cache: Cache[K, V], k: K): bool =
  result = cache.hasNodeInStore(k)

proc del*[K, V](cache: Cache[K, V], k: K): V =
  let node = cache.getNodeFromStore(k)
  if node != nil:
    cache.delNodeFromStore(node)
    cache.delNode(node)
    result = node.value
  else:
    raise newException(KeyError, "key not found")

proc add*[K, V](cache: Cache[K, V], k: K, v: sink V) =
  if cache.has(k):
    cache.getNodeFromStore(k).value = v
  else:
    let node = Node[K, V](key: k, value: v)
    cache.addNodeToStore(node)
    cache.addNode(node)

proc get*[K, V](cache: Cache[K, V], k: K): V =
  let node = cache.getNodeFromStore(k)
  if node != nil:
    node.visited = true
    result = node.value
  else:
    raise newException(KeyError, "key not found")

proc getOrDefault*[K, V](cache: Cache[K, V], k: K, def: V): V =
  try:
    result = cache.get(k)
  except:
    result = def

proc `[]`*[K, V](cache: Cache[K, V], k: K): V =
  result = cache.get(k)

proc `[]=`*[K, V](cache: Cache[K, V], k: K, v: V) =
  cache.add(k, v)
