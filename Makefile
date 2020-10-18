build:
	WINEDEBUG=-all ${GOWIN_SH} build.tcl

.PHONY: flash
flash: build
	sudo docker run --privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
	-v ${shell pwd}/impl/pnr:/var/binary -it pepijndevos/apicula /bin/bash -c "apt -y install kmod; /usr/src/gowin/Programmer/bin/programmer_cli -d "GW1N-1" -r2 -f /var/binary/project.fs"

.PHONY: burn
burn: build
	sudo docker run --privileged --cap-add=ALL -v /dev:/dev -v /lib/modules:/lib/modules \
	-v ${shell pwd}/impl/pnr:/var/binary -it pepijndevos/apicula /bin/bash -c "apt -y install kmod; /usr/src/gowin/Programmer/bin/programmer_cli -d "GW1N-1" -r5 -f /var/binary/project.fs"

.PHONY: clean
clean:
	rm -rf impl
