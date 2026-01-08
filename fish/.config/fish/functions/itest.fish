function itest --wraps='make integration-tests-bookcore args="-k $argv"' --description 'make integration-tests-bookcore args="-k $argv"'
  make integration-tests-bookcore args="-k $argv"
end
