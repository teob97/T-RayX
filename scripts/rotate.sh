for angle in $(seq 0 90); do
    # Angle with three digits, e.g. angle="1" → angleNNN="001"
    angleNNN=$(printf "%03d" $angle)
    ./../trayx render exampleInput.txt 600 600 --renderer=pointlight --defineFloat=clock:$angle --output=../output/demo/img$angleNNN.png
done

# -r 25: Number of frames per second
ffmpeg -r 25 -f image2 -s 600x600 -i ../output/demo/img%03d.png \
    -vcodec libx264 -pix_fmt yuv420p \
    ../output/demo/point_light_rot.mp4