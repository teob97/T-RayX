for angle in $1; do
	./trayx render exampleInput.txt 480 360 --clock=$angle --output=$angle.png
done

# parallel -j NUM_OF_CORES ./test-parallel.sh '{}' ::: $(seq 0 359)