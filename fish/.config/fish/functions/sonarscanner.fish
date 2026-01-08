function sonarscanner --wraps='sonarscanner' --description 'sonarscanner'
  set sonarhost "http://sonarqube:9000"

  if set -q argv[2]
    set path $argv[2]
  else
    set path "./"
  end

  docker run --rm \
  --network sonarqube \
  -e SONAR_HOST_URL="$sonarhost" \
  -e SONAR_TOKEN="$argv[1]" \
  -v "$(realpath $path):/usr/src" \
  sonarsource/sonar-scanner-cli
end
