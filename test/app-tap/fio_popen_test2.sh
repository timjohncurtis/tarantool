#!/bin/bash
for i in {1..10}
do
	1>&2 echo $i
	echo $i
done

