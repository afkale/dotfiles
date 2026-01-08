function devel --wraps='ssh -p 2245 bookcore@crsdevel02.bookcore.test.roiback' --description 'alias devel ssh -p 2245 bookcore@crsdevel02.bookcore.test.roiback'
  ssh -p 2245 bookcore@crsdevel02.bookcore.test.roiback $argv
end
