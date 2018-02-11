#!/bin/sh

scale_testing_dir=/root/scale-testing
controller_name=pbench-controller
controllers="$(docker ps -a --filter name=pbench-controller --format '{{.ID}}')"
docker_complete_message="OCP SCALE TEST COMPLETE"
docker_fail_message="OCP SCALE TEST FAILED"

# Currently there doesn't seem to be a way to make the $controller_name
# pod exit once the test is done.  Thus this ugly hack.
run_complete_block() {
  local docker_id="$1"

  echo "Blocking while container $docker_id runs." >&2
  while true; do
    docker logs $docker_id | grep -q "$docker_complete_message" && return 0
    docker logs $docker_id | grep -q "$docker_fail_message" && return 1
    sleep 5
  done
}

if test "$controllers" ; then
  docker rm -f "$controllers"
fi

docker_id=$(docker run -t -d --name="$controller_name" --net=host --privileged \
#  -v /var/lib/pbench-agent:/var/lib/pbench-agent \
  -v $scale_testing_dir/results:/var/lib/pbench-agent \
  -v $scale_testing_dir/inventory:/root/inventory \
  -v $scale_testing_dir/vars:/root/vars \
  -v $scale_testing_dir/keys:/root/.ssh \
  -v $scale_testing_dir/benchmark.sh:/root/benchmark.sh pbench-controller)

#test "$docker_id" && docker logs -f $docker_id
test "$docker_id" || exit 1
echo "docker logs -f $docker_id" >&2
run_complete_block "$docker_id"
docker rm -f "$docker_id" > /dev/null 2>&1	# don't echo removed container id
