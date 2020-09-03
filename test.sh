#!/bin/sh

mkdir /kaniko && mkdir /kaniko/.docker

__run() {
  actual=$(env UNIT_TEST=true $1 ./plugin.sh)
  echo $actual > .actual
  echo $2 > .expected
  cmp -s .actual .expected

  if [ $? != 0 ]; then
    echo "Failed:"
    echo -e "\tActual:\t\t\"$actual\""
    echo -e "\tExpected:\t\"$2\""
    exit 1
  fi

  rm .actual .expected
}

__check_file() {
  if [ -n "${1:-}" ]; then
    if [ -f "$1" ]; then
      echo $(cat $1) > .actual
      echo $2 > .expected
      cmp -s .actual .expected

      if [ $? != 0 ]; then
        echo "Failed:"
        echo -e "\tActual:\t\t\"$actual\""
        echo -e "\tExpected:\t\"$2\""
        exit 1
      fi

      rm $1 .actual .expected
    else
      echo "$1 file(s) not generated"
      exit 1
    fi
  fi
}

# Test Case 1
env=''
output='/kaniko/executor -v info --context=/drone/src --dockerfile=Dockerfile --no-push'
__run "$env" "$output"
echo "Success"

# Test Case 2 (Deprecated Feature)
env='PLUGIN_REPO=test_repo PLUGIN_JSON_KEY=test_json_key'
output='PLUGIN_JSON_KEY is deprecated. Use PLUGIN_AUTHJSON_GCR instead
/kaniko/executor -v info --context=/drone/src --dockerfile=Dockerfile --destination=index.docker.io/test_repo:latest'
__run "$env" "$output"
__check_file "/kaniko/gcr.json" "test_json_key"
echo "Success"

# Test Case 3
env='PLUGIN_REPO=test_repo PLUGIN_USERNAME=test_username PLUGIN_PASSWORD=test_password PLUGIN_AUTO_TAG=true DRONE_TAG=1.2.3 PLUGIN_BUILD_ARGS_FROM_ENV=test1,test2 test1=1 test2=2 PLUGIN_TARGET=test_target'
output='/kaniko/executor -v info --context=/drone/src --dockerfile=Dockerfile --destination=index.docker.io/test_repo:1 --destination=index.docker.io/test_repo:1.2 --destination=index.docker.io/test_repo:1.2.3 --destination=index.docker.io/test_repo:latest --target=test_target --build-arg test1=1 --build-arg test2=2'
__run "$env" "$output"
__check_file ".tags" "1,1.2,1.2.3,latest"
__check_file "/kaniko/.docker/config.json" "{
    \"auths\": {
        \"index.docker.io\": {
            \"auth\": \"dGVzdF91c2VybmFtZTp0ZXN0X3Bhc3N3b3Jk\"
        }
    }
}"
echo "Success"

# Test Case 4
env='PLUGIN_LOG=debug PLUGIN_REGISTRY=test_registry PLUGIN_REPO=test_repo PLUGIN_TAGS=test_tags PLUGIN_CACHE=true PLUGIN_CACHE_REPO=test_cache_repo PLUGIN_CACHE_TTL=test_cache_ttl PLUGIN_SKIP_TLS_VERIFY=true PLUGIN_BUILD_ARGS=test_build_args'
output='/kaniko/executor -v debug --context=/drone/src --dockerfile=Dockerfile --skip-tls-verify=true --destination=test_registry/test_repo:test_tags --cache=true --cache-ttl=test_cache_ttl --cache-repo=test_registry/test_cache_repo --build-arg=test_build_args'
__run "$env" "$output"
echo "Success"

# Test Case 5
env='PLUGIN_REPO=test_repo PLUGIN_AUTHJSON_DOCKER=test_json_key'
output='/kaniko/executor -v info --context=/drone/src --dockerfile=Dockerfile --destination=index.docker.io/test_repo:latest'
__run "$env" "$output"
__check_file "/kaniko/.docker/config.json" "test_json_key"
echo "Success"

# Test Case 6
env='PLUGIN_REPO=test_repo PLUGIN_AUTHJSON_GCR=test_json_key'
output='/kaniko/executor -v info --context=/drone/src --dockerfile=Dockerfile --destination=index.docker.io/test_repo:latest'
__run "$env" "$output"
__check_file "/kaniko/gcr.json" "test_json_key"
echo "Success"

# Test Case 7
env='PLUGIN_REPO=test_repo PLUGIN_AUTHJSON_AWS=test_json_key'
output='/kaniko/executor -v info --context=/drone/src --dockerfile=Dockerfile --destination=index.docker.io/test_repo:latest'
__run "$env" "$output"
__check_file "/root/.aws/credentials" "test_json_key"
echo "Success"
