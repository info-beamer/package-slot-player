from heapq import heappush, heappop

def gcd(a, b):
    """Return greatest common divisor using Euclid's Algorithm."""
    while b:      
        a, b = b, a % b
    return a

def lcm(a, b):
    """Return lowest common multiple."""
    return a * b // gcd(a, b)

def lcmm(nums):
    """Return lcm of args."""   
    return reduce(lcm, nums)

class Slots(object):
    def __init__(self, content):
        self._content = content
        self._q = None
        if not content:
            return

        common = lcmm(item['slots'] for item in content)
        self._slotw = [
            common / item['slots']
            for item in content
        ]
        self._q = [
            (0, self._slotw[idx], idx)
            for idx in xrange(len(content))
        ]
        self._last_idx = None

    def get_next(self):
        if not self._q:
            return None

        w, x, idx = heappop(self._q)

        # Playing the same idx twice? See if there is an alternative
        if idx == self._last_idx and len(self._content) > 2:
            # print((w, idx), self._q)
            alt_w, alt_x, alt_idx = heappop(self._q)
            if alt_w != w:
                # nope. cannot swap with next item
                heappush(self._q, (alt_w, alt_x, alt_idx))
            else:
                heappush(self._q, (w, x, idx))
                w, idx = alt_w, alt_idx

        self._last_idx = idx

        heappush(self._q, (w + self._slotw[idx], x, idx))
        return self._content[idx]

if __name__ == "__main__":
    from collections import defaultdict
    s = Slots([
        # {'slots': 100, 'name': 'a==='},
        # {'slots': 200, 'name': 'b   }}}'},
        # {'slots': 100, 'name': 'c      ###'},
        {'slots': 800, 'name': 'a==='},
        {'slots': 300, 'name': 'b   }}}'},
        {'slots':  80, 'name': 'c      ###'},
        {'slots': 200, 'name': 'd         !!!'},
        {'slots': 250, 'name': 'e            %%%'},
    ])

    c = defaultdict(int)
    for i in xrange(sum(i['slots'] for i in s._content)):
        item = s.get_next()
        print(item['name'])
        c[item['name']] += 1
    for name, count in sorted(c.iteritems()):
        print(name, count)
