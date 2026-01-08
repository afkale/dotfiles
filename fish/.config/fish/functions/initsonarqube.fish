function initsonarqube --wraps='' --description 'initsonarqube'
  set network $(docker network ls --format '{{.Name}}' | grep '^sonarqube$')

  if test -z "$network"
    docker network create -d bridge sonarqube
  end

  docker run -d --rm --name sonarqube -p 9000:9000 --network sonarqube sonarqube:community
end
