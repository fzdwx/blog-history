package main

import (
	"fmt"
	"sync"
)

func main() {
	for n := 0; n < 10; n++ {
		var (
			count = 1
			n     = 1000000
			wg    = sync.WaitGroup{}
		)
		wg.Add(2)
		for i := 0; i < 2; i++ {
			go func() {
				defer wg.Done()
				for j := 0; j < n; j++ {
					count++
				}
			}()
		}

		wg.Wait()
		fmt.Println(count)
	}
}

// output:
// 1378924  1133362  1031662  1031665  1090521  1221675  1266065  1157836  1326654  1023312
