
;;;; package.lisp

(defpackage #:py4cl2
  (:use #:cl #:iterate)
  (:shadowing-import-from #:iterate #:as #:for)
  (:export ; python-process
   #:pystart
   #:with-python-output
   #:pystop
   #:python-alive-p
   #:python-start-if-not-alive
   #:pyinterrupt)
  (:export ; callpython
   #:pyerror
   #:raw-pyeval
   #:raw-pyexec
   #:pyeval
   #:pyexec
   #:pycall
   #:pymethod 
   #:pygenerator 
   #:pyslot-value 
   #:pyversion-info
   #:pyhelp 
   #:chain
   #:chain*
   #:@
   #:with-remote-objects
   #:with-remote-objects*)
  (:export ; import-export
   #:pymethod-list 
   #:pyslot-list 
   #:defpyfun  
   #:defpymodule
   #:*defpymodule-silent-p*
   #:defpyfuns
   #:export-function)
  (:export ; lisp-classes
   #:python-getattr)
  (:export ; config 
   #:*config*
   #:initialize
   #:save-config
   #:load-config
   #:config-var
   #:pycmd
   #:numpy-pickle-location
   #:numpy-pickle-lower-bound
   #:use-numcl-arrays
   #:with-numcl-arrays
   #:py-cd))
