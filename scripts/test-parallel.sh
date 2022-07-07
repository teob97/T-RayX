for angle in $1; do
    ./../trayx render ../exampleInput.txt 600 600 --renderer=pointlight --defineFloat=clock:$angle --output=../output/demo/img$angleNNN.png
done

# Use:
# parallel -j NUM_OF_CORES ./test-parallel.sh '{}' ::: $(seq 0 359)