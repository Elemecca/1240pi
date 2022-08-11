
V_FILES = VideoOut.v


video_proto.bin: video_proto.asc
	icepack video_proto.asc video_proto.bin

video_proto.asc: video_proto.json video_proto.pcf
	nextpnr-ice40 --hx8k --json video_proto.json --pcf video_proto.pcf --asc video_proto.asc

video_proto.json: $(V_FILES)
	yosys -p "synth_ice40 -top VideoOut -json video_proto.json" $(V_FILES)


.PHONY: flash
flash: video_proto.bin
	iceprog video_proto.bin

.PHONY: clean
clean:
	rm -f video_proto.json video_proto.asc video_proto.bin

