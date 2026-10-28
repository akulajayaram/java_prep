# DSA Preparation Guide for 3 Years Exp Java / Spring Boot / Microservices Developer

This guide is curated specifically for a **3-year experienced Java Backend Developer** preparing for technical interviews at product-based companies and top tech firms.

At **3 YOE**, interviewers expect:
1. **High proficiency in Medium-level LeetCode problems** (solving within 20–25 minutes).
2. **Clean, production-grade Java code** (proper variable naming, edge case handling, optimal Collections API usage).
3. **Backend / System-Flavored DSA**: Questions that mimic microservices and backend internals (LRU caches, Rate Limiters, Dependency graphs, TTL stores, Concurrency).
4. **Strong grasp of Java Collection Internals and Complexity Analysis ($O(N)$, $O(\log N)$, Space vs. Time trade-offs)**.

---

## Table of Contents
1. [Backend & Microservices Flavored DSA (Top Priority)](#1-backend--microservices-flavored-dsa-top-priority)
2. [High-Frequency Data Structures & Patterns](#2-high-frequency-data-structures--patterns)
   - [Arrays, Two Pointers & Sliding Window](#a-arrays-two-pointers--sliding-window)
   - [Hashing & Strings](#b-hashing--strings)
   - [Linked Lists](#c-linked-lists)
   - [Stacks, Queues & Monotonic Structures](#d-stacks-queues--monotonic-structures)
   - [Binary Trees & Binary Search Trees (BST)](#e-binary-trees--binary-search-trees-bst)
   - [Heaps & PriorityQueues](#f-heaps--priorityqueues)
   - [Graphs (BFS, DFS, Topological Sort)](#g-graphs-bfs-dfs-topological-sort)
   - [Dynamic Programming & Greedy (Core Essentials)](#h-dynamic-programming--greedy-core-essentials)
3. [Java Collections & Concurrency Under the Hood](#3-java-collections--concurrency-under-the-hood)
4. [4-Week Preparation Roadmap](#4-4-week-preparation-roadmap)

---

## 1. Backend & Microservices Flavored DSA (Top Priority)

These problems bridge the gap between pure algorithms and real-world microservice architectures. Interviewers frequently ask these in 3 YOE backend rounds.

| # | Problem | Why It Matters for Microservices | Key Data Structures | LeetCode / Difficulty |
|---|---------|-----------------------------------|----------------------|-----------------------|
| 1 | **LRU Cache Implementation** | Used in distributed caching (Redis/Hazelcast/Caffeine) eviction policies. | `HashMap` + Doubly Linked List / `LinkedHashMap` | [LC 146](https://leetcode.com/problems/lru-cache/) (Medium) |
| 2 | **LFU Cache Implementation** | Frequency-based cache eviction policy. | Double HashMaps + Doubly Linked Lists | [LC 460](https://leetcode.com/problems/lfu-cache/) (Hard) |
| 3 | **Rate Limiter (Token Bucket / Sliding Window Log)** | API Gateway rate limiting (Resilience4j / Spring Cloud Gateway). | Queue / Monotonic Deque / Atomic variables | Concept / LLD (Medium) |
| 4 | **In-Memory Key-Value Store with TTL (Time-To-Live)** | Microservices session caching, token expiration, cache-aside. | `ConcurrentHashMap` + `DelayQueue` / `PriorityQueue` | System / DSA (Medium) |
| 5 | **Microservices Dependency Resolution (Circular Dependency Check)** | Spring Bean dependency injection resolution, Service startup order in Kubernetes / Helm DAGs. | Topological Sort (Kahn's Algo / DFS Cycle Check) | [LC 207](https://leetcode.com/problems/course-schedule/) & [LC 210](https://leetcode.com/problems/course-schedule-ii/) (Medium) |
| 6 | **API Route Matcher (Prefix / Wildcard Routing)** | API Gateway routing logic (e.g., `/api/v1/users/{id}`). | Trie (Prefix Tree) | [LC 208](https://leetcode.com/problems/implement-trie-prefix-tree/) (Medium) |
| 7 | **Thread-Safe Bounded Blocking Queue** | Asynchronous message processing (Kafka consumer threads, thread pools). | Mutex / `ReentrantLock` + Conditions (`notFull`, `notEmpty`) | [LC 1188](https://leetcode.com/problems/design-bounded-blocking-queue/) (Medium) |
| 8 | **Top K Frequent Elements / Real-Time Metrics Aggregator** | Log analysis, tracking top API endpoints by traffic, error counting. | Min-Heap (`PriorityQueue`) or Bucket Sort | [LC 347](https://leetcode.com/problems/top-k-frequent-elements/) (Medium) |
| 9 | **Sliding Window Failure Rate (Circuit Breaker Simulation)** | Resilience4j circuit breaker state transition (Closed -> Open on error threshold). | Ring Buffer / Sliding Window Counter | Real-world LLD (Medium) |
| 10 | **Consistent Hashing Simulation** | Distributed database sharding, routing requests across microservice replicas. | `TreeMap` (Red-Black Tree for ring navigation) | System Design / DSA (Medium) |

---

## 2. High-Frequency Data Structures & Patterns

### A. Arrays, Two Pointers & Sliding Window
Essential for streaming data, metric window calculation, and search algorithms.

1. **Subarray Sum Equals K** ([LC 560](https://leetcode.com/problems/subarray-sum-equals-k/)) - *Medium*
   - *Pattern:* Prefix Sum + HashMap
   - *Core Concept:* $O(N)$ time with $O(N)$ space using rolling prefix sums.
2. **Longest Substring Without Repeating Characters** ([LC 3](https://leetcode.com/problems/longest-substring-without-repeating-characters/)) - *Medium*
   - *Pattern:* Sliding Window + Frequency Map / Set
   - *Core Concept:* Dynamic window resizing with `left` and `right` pointers.
3. **Minimum Window Substring** ([LC 76](https://leetcode.com/problems/minimum-window-substring/)) - *Hard*
   - *Pattern:* Sliding Window with Target Character Map
4. **3Sum** ([LC 15](https://leetcode.com/problems/3sum/)) - *Medium*
   - *Pattern:* Sorting + Two Pointers (avoiding duplicate triplets)
5. **Container With Most Water** ([LC 11](https://leetcode.com/problems/container-with-most-water/)) - *Medium*
   - *Pattern:* Greedy Two Pointers from both ends inwards
6. **Trapping Rain Water** ([LC 42](https://leetcode.com/problems/trapping-rain-water/)) - *Hard*
   - *Pattern:* Two Pointers or Monotonic Stack
7. **Merge Intervals** ([LC 56](https://leetcode.com/problems/merge-intervals/)) & **Insert Interval** ([LC 57](https://leetcode.com/problems/insert-interval/)) - *Medium*
   - *Pattern:* Interval sorting + Overlap comparison (common in scheduling tasks)
8. **Maximum Subarray (Kadane’s Algorithm)** ([LC 53](https://leetcode.com/problems/maximum-subarray/)) - *Medium*
   - *Pattern:* Dynamic Programming / Running local vs global maximum

---

### B. Hashing & Strings
Data parsing, deduplication, JSON/payload processing, idempotency checks.

1. **Group Anagrams** ([LC 49](https://leetcode.com/problems/group-anagrams/)) - *Medium*
   - *Pattern:* Categorize by sorted string or character frequency array as map key.
2. **Longest Consecutive Sequence** ([LC 128](https://leetcode.com/problems/longest-consecutive-sequence/)) - *Medium*
   - *Pattern:* HashSet with sequence head lookup ($O(N)$ time).
3. **Find All Anagrams in a String** ([LC 438](https://leetcode.com/problems/find-all-anagrams-in-a-string/)) - *Medium*
   - *Pattern:* Fixed Sliding Window + Array frequency count.
4. **Encode and Decode Strings** ([LC 271](https://leetcode.com/problems/encode-and-decode-strings/)) - *Medium*
   - *Pattern:* Delimiter-length encoding (mirrors serialization protocols).

---

### C. Linked Lists
Pointer manipulation, memory reference understanding, building blocks for custom structures.

1. **Reverse a Linked List** ([LC 206](https://leetcode.com/problems/reverse-linked-list/)) - *Easy*
   - *Pattern:* Iterative 3-pointer technique & Recursive approach.
2. **Detect and Find Start of Cycle in Linked List** ([LC 141](https://leetcode.com/problems/linked-list-cycle/) & [LC 142](https://leetcode.com/problems/linked-list-cycle-ii/)) - *Medium*
   - *Pattern:* Floyd’s Tortoise and Hare (Slow & Fast Pointers).
3. **Merge Two Sorted Lists** ([LC 21](https://leetcode.com/problems/merge-two-sorted-lists/)) & **Merge K Sorted Lists** ([LC 23](https://leetcode.com/problems/merge-k-sorted-lists/)) - *Hard*
   - *Pattern:* Min-Heap (`PriorityQueue`) or Divide & Conquer (common in merging partitioned DB query results).
4. **Copy List with Random Pointer** ([LC 138](https://leetcode.com/problems/copy-list-with-random-pointer/)) - *Medium*
   - *Pattern:* HashMap or In-place Interweaving Node copy (deep copy concepts).
5. **Reorder List** ([LC 143](https://leetcode.com/problems/reorder-list/)) - *Medium*
   - *Pattern:* Middle finding + Reverse second half + Alternate merge.

---

### D. Stacks, Queues & Monotonic Structures
Backpressure, parsing nested payloads, monotonic tracking for order processing.

1. **Valid Parentheses** ([LC 20](https://leetcode.com/problems/valid-parentheses/)) - *Easy*
   - *Pattern:* Basic Stack (JSON/XML validation basis).
2. **Min Stack** ([LC 155](https://leetcode.com/problems/min-stack/)) - *Medium*
   - *Pattern:* Auxiliary stack or tracking state tuple `(val, minVal)`.
3. **Daily Temperatures** ([LC 739](https://leetcode.com/problems/daily-temperatures/)) - *Medium*
   - *Pattern:* Monotonic Decreasing Stack.
4. **Next Greater Element I & II** ([LC 496](https://leetcode.com/problems/next-greater-element-i/) & [LC 503](https://leetcode.com/problems/next-greater-element-ii/)) - *Medium*
   - *Pattern:* Monotonic Stack + Circular array index modulo `i % N`.
5. **Sliding Window Maximum** ([LC 239](https://leetcode.com/problems/sliding-window-maximum/)) - *Hard*
   - *Pattern:* Monotonic Double-Ended Queue (`ArrayDeque`).
6. **Evaluate Reverse Polish Notation** ([LC 150](https://leetcode.com/problems/evaluate-reverse-polish-notation/)) - *Medium*
   - *Pattern:* Stack operand evaluation (expression parsers, SQL query plan evaluations).

---

### E. Binary Trees & Binary Search Trees (BST)
Hierarchical structures, category trees, indexes in databases (B-Tree foundation).

1. **Maximum Depth & Diameter of Binary Tree** ([LC 104](https://leetcode.com/problems/maximum-depth-of-binary-tree/) & [LC 543](https://leetcode.com/problems/diameter-of-binary-tree/)) - *Easy/Medium*
   - *Pattern:* Post-order DFS.
2. **Lowest Common Ancestor of a Binary Tree** ([LC 236](https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-tree/)) - *Medium*
   - *Pattern:* Recursive backtracking (Org hierarchy, manager tree lookup).
3. **Binary Tree Level Order Traversal** ([LC 102](https://leetcode.com/problems/binary-tree-level-order-traversal/)) - *Medium*
   - *Pattern:* Queue-based BFS.
4. **Binary Tree Zigzag Level Order Traversal** ([LC 103](https://leetcode.com/problems/binary-tree-zigzag-level-order-traversal/)) - *Medium*
   - *Pattern:* BFS with Deque or level inversion.
5. **Validate Binary Search Tree** ([LC 98](https://leetcode.com/problems/validate-binary-search-tree/)) - *Medium*
   - *Pattern:* In-order traversal (strictly increasing) or `(low, high)` range propagation.
6. **Kth Smallest Element in a BST** ([LC 230](https://leetcode.com/problems/kth-smallest-element-in-a-bst/)) - *Medium*
   - *Pattern:* Iterative In-order traversal with early stop.
7. **Serialize and Deserialize Binary Tree** ([LC 297](https://leetcode.com/problems/serialize-and-deserialize-binary-tree/)) - *Hard*
   - *Pattern:* Pre-order traversal with delimiter and null placeholders (mirrors JSON/Protobuf object serialization).
8. **Binary Tree Right Side View** ([LC 199](https://leetcode.com/problems/binary-tree-right-side-view/)) - *Medium*
   - *Pattern:* Level Order BFS (picking the last element of each queue snapshot).

---

### F. Heaps & PriorityQueues
Priority processing, event schedulers, top metrics, median trackers.

1. **Kth Largest Element in an Array** ([LC 215](https://leetcode.com/problems/kth-largest-element-in-an-array/)) - *Medium*
   - *Pattern:* Min-Heap of size $K$ or Quickselect ($O(N)$ average time).
2. **Find Median from Data Stream** ([LC 295](https://leetcode.com/problems/find-median-from-data-stream/)) - *Hard*
   - *Pattern:* Two Heaps (Max-Heap for lower half, Min-Heap for upper half).
3. **Task Scheduler** ([LC 621](https://leetcode.com/problems/task-scheduler/)) - *Medium*
   - *Pattern:* Max-Heap + Cooldown Queue or Greedy frequency math.
4. **K Closest Points to Origin** ([LC 973](https://leetcode.com/problems/k-closest-points-to-origin/)) - *Medium*
   - *Pattern:* Max-Heap of size $K$ using custom Comparator.

---

### G. Graphs (BFS, DFS, Topological Sort)
Microservice network topologies, async workflow orchestration, permission trees.

1. **Number of Islands** ([LC 200](https://leetcode.com/problems/number-of-islands/)) - *Medium*
   - *Pattern:* Matrix BFS/DFS connected components (Standard interview warm-up).
2. **Rotting Oranges** ([LC 994](https://leetcode.com/problems/rotting-oranges/)) - *Medium*
   - *Pattern:* Multi-source BFS with time-step level tracking.
3. **Course Schedule I & II (Detect Cycle & Order)** ([LC 207](https://leetcode.com/problems/course-schedule/) & [LC 210](https://leetcode.com/problems/course-schedule-ii/)) - *Medium*
   - *Pattern:*
     - Kahn's Algorithm (BFS with In-degrees).
     - DFS with 3-color node state (`0=UNVISITED`, `1=VISITING`, `2=VISITED`).
   - *Application:* Detecting circular microservice dependencies or build task ordering.
4. **Clone Graph** ([LC 133](https://leetcode.com/problems/clone-graph/)) - *Medium*
   - *Pattern:* HashMap tracking visited/copied nodes + BFS/DFS.
5. **Word Ladder** ([LC 127](https://leetcode.com/problems/word-ladder/)) - *Hard*
   - *Pattern:* Shortest path in unweighted graph using BFS with Set.
6. **Network Delay Time** ([LC 743](https://leetcode.com/problems/network-delay-time/)) - *Medium*
   - *Pattern:* Dijkstra’s Algorithm using `PriorityQueue`.

---

### H. Dynamic Programming & Greedy (Core Essentials)
Resource optimization, cost minimization, transaction limits. (3 YOE focuses primarily on 1D/2D DP patterns).

1. **Coin Change** ([LC 322](https://leetcode.com/problems/coin-change/)) - *Medium*
   - *Pattern:* Unbounded Knapsack / Minimum combination DP.
2. **Longest Increasing Subsequence (LIS)** ([LC 300](https://leetcode.com/problems/longest-increasing-subsequence/)) - *Medium*
   - *Pattern:* $O(N^2)$ DP or $O(N \log N)$ Binary Search with Patience Sorting.
3. **House Robber I & II** ([LC 198](https://leetcode.com/problems/house-robber/) & [LC 213](https://leetcode.com/problems/house-robber-ii/)) - *Medium*
   - *Pattern:* 1D DP with state transition `dp[i] = max(dp[i-1], dp[i-2] + nums[i])`.
4. **Word Break** ([LC 139](https://leetcode.com/problems/word-break/)) - *Medium*
   - *Pattern:* 1D Boolean DP with dictionary lookup.
5. **Partition Equal Subset Sum** ([LC 416](https://leetcode.com/problems/partition-equal-subset-sum/)) - *Medium*
   - *Pattern:* 0/1 Knapsack subset problem.
6. **Longest Common Subsequence (LCS)** ([LC 1143](https://leetcode.com/problems/longest-common-subsequence/)) - *Medium*
   - *Pattern:* 2D Grid DP (Diff engines, versioning comparison).

---

## 3. Java Collections & Concurrency Under the Hood

Interviewers testing 3 YOE Java developers will consistently probe your understanding of Java standard library internals and thread-safety:

### 1. `HashMap` Internals (Java 8+)
- **Internal Structure:** Array of Nodes (buckets) transitioning to Red-Black Trees (`TreeNode`) when bucket size exceeds `TREEIFY_THRESHOLD = 8` and `MIN_TREEIFY_CAPACITY >= 64`.
- **Hash function:** `(key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16)` (spread higher bits down).
- **Index Calculation:** `index = (n - 1) & hash` (requires power-of-two table size).
- **Collision Handling:** Separate chaining with Linked List; converts back to linked list (`UNTREEIFY_THRESHOLD = 6`) during resizing.
- **Resize / Rehashing:** Doubled when `size > threshold (capacity * loadFactor 0.75)`.

### 2. `ConcurrentHashMap` Internals
- **Java 7 vs Java 8:**
  - Java 7: `Segment` array (ReentrantLock on segments; default concurrency level 16).
  - Java 8+: No segments! Fine-grained bucket-level locking using `synchronized` on the head node of each bucket + `Unsafe`/`VarHandle` CAS (Compare-And-Swap) for empty bucket insertions.
- **`size()` implementation:** Uses `CounterCell` array (similar to `LongAdder`) to avoid single variable contention across multiple threads.

### 3. `ArrayList` vs `LinkedList` vs `ArrayDeque`
- **Cache Locality:** `ArrayList` uses contiguous memory, causing far fewer CPU cache misses than pointer-chasing in `LinkedList`.
- **Queue/Stack Choice:** Never use `Stack` (legacy, extends `Vector`, synchronized methods) or `LinkedList` as a queue/stack. Always use `ArrayDeque` (faster, no node allocation overhead).

### 4. `LinkedHashMap` for LRU Cache
- Overriding `removeEldestEntry(Map.Entry<K,V> eldest)` allows instant LRU cache implementation when initialized with `accessOrder = true`.

### 5. `PriorityQueue` Internals
- Backed by an array representing a balanced binary heap (`parent = (i - 1) / 2`, `left = 2 * i + 1`, `right = 2 * i + 2`).
- Offer/Poll complexity: $O(\log N)$, Peek: $O(1)$. Unordered during iteration!

---

## 4. 4-Week Preparation Roadmap

### Week 1: Arrays, Strings, HashMaps & Sliding Window
- [ ] Master Two-pointer patterns (3Sum, Container With Most Water).
- [ ] Master Sliding Window (Longest Substring Without Repeating Characters, Minimum Window Substring).
- [ ] Master Prefix Sum + HashMap (Subarray Sum Equals K).
- [ ] Practice Group Anagrams and Longest Consecutive Sequence.
- [ ] **Goal:** 15–20 questions solved.

### Week 2: Linked Lists, Stacks, Queues & System-Flavored DSA
- [ ] Implement **LRU Cache** from scratch (Doubly Linked List + HashMap) without using `LinkedHashMap`.
- [ ] Reverse Linked List, Cycle detection (Floyd’s algorithm).
- [ ] Monotonic Stack (Daily Temperatures, Next Greater Element).
- [ ] Implement **Thread-Safe Bounded Blocking Queue** using `ReentrantLock` & `Condition`.
- [ ] Implement **Token Bucket / Sliding Window Rate Limiter**.
- [ ] **Goal:** 15 questions + 2 design implementations.

### Week 3: Trees, BSTs & Graphs
- [ ] Binary Tree traversals (In-order, Pre-order, Post-order, Level Order BFS).
- [ ] Lowest Common Ancestor (LCA) & Validate BST.
- [ ] Serialize & Deserialize Binary Tree.
- [ ] Graph DFS/BFS (Number of Islands, Rotting Oranges).
- [ ] **Topological Sort** (Course Schedule I & II) — crucial for microservice dependency questions.
- [ ] **Goal:** 15–18 questions.

### Week 4: Heaps, Dynamic Programming & Java Internals
- [ ] Min/Max Heap problems (Top K Frequent Elements, Find Median from Data Stream).
- [ ] Dynamic Programming essentials (Coin Change, LIS, House Robber, Word Break).
- [ ] Revise Java Collection internals: `HashMap`, `ConcurrentHashMap`, `LinkedHashMap`, `ArrayDeque`.
- [ ] Conduct 2–3 timed mock coding interviews (45 mins: 2 LeetCode Mediums).
- [ ] **Goal:** 12 questions + complete theoretical revision.

---

## 5. Coding Interview Tips for 3 YOE

1. **Clarify Edge Cases Before Writing Code:**
   - Null checks, empty collections, single element, negative numbers, duplicates, integer overflow (`Integer.MAX_VALUE`).
2. **Communicate Thought Process First:**
   - State brute force solution and its time/space complexity ($O(N^2)$).
   - Propose optimal solution ($O(N)$ or $O(N \log N)$) and explain the data structure choice before coding.
3. **Use Idiomatic Java:**
   - Leverage `Map.getOrDefault()`, `Map.computeIfAbsent()`, `ArrayDeque`, `Collections.sort()` with lambdas or `Comparator.comparing()`.
4. **Dry Run with a Small Test Case:**
   - Walk through your code line by line with an example input before saying "I am done".
