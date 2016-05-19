args <- commandArgs(TRUE)

if (identical(args[1],"SETUP")) {
  chooseBioCmirror(graphics = getOption("menu.graphics"),ind=3)
  chooseCRANmirror(graphics = getOption("menu.graphics"), ind = 49)
  setRepositories(graphics = getOption("menu.graphics"), ind = c(1,2,3,4,5,6))
  print ("Mirrors and Repositories set-up done.")
  } else is.element(args[1], installed.packages()[,1])
