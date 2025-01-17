(in-package :py4cl2)

(defvar *config* () "Configuration variable used to store configuration values for PY4CL2.
This variable should be manipulated using CONFIG-VAR and (SETF CONFIG-VAR).")
;; Refer initialize function to note which variables are included under *config*

(defvar *array-type* :cl)

(defvar *arrayfiers* (list :cl #'identity)
  "(GETF *ARRAYFIERS* *ARRAY-TYPE*) should return a single argument function that converts the ARRAY into the required type.")

(setf (documentation '*array-type* 'variable) (documentation '*arrayfiers* 'variable))

#.(progn
    (alexandria:define-constant +py4cl2-config-path+
        (namestring (asdf:component-pathname (asdf:find-component "py4cl2" ".config")))
      :test 'equal)
    `(alexandria:define-constant +py4cl2-config-path+
         (namestring (asdf:component-pathname (asdf:find-component "py4cl2" ".config")))
       :test 'equal))

(defun take-input (prompt default)
  (format t prompt)
  (force-output)
  (let ((input (read-line)))
    (if (string= "" input) default input)))

(defun initialize ()
  "Intended to be called first upon installation. Sets up default python command,
and numpy pickle file and lower bounds."
  (let ((pycmd (take-input "Provide the path to python binary to use (default python): "
                           "python"))
        (numpy-pickle-location
         (take-input "~%PY4CL2 uses pickled files to transfer large arrays between lisp
 and python efficiently. These are expected to have sizes exceeding 100MB
 (this depends on the value of *NUMPY-PICKLE-LOWER-BOUND*). Therefore, choose an
 appropriate location (*NUMPY-PICKLE-LOCATION*) for storing these arrays on disk.

Enter full file path for storage (default /tmp/_numpy_pickle.npy): "
                     "/tmp/_numpy_pickle.npy"))
        (numpy-pickle-lower-bound
         (parse-integer
          (take-input "Enter lower bound for using pickling (default 100000): "
                      "100000")))
        (use-numcl-arrays
         (let ((*read-eval* nil))
           (read-from-string (take-input "Use numcl arrays [t/nil] (default t) [Note that this would only take effect if PY4CL2+NUMCL system is loaded]: " "t")))))
    (setq  *config* ;; case conversion to and from symbols is handled by cl-json
           `((pycmd . ,pycmd)
             (numpy-pickle-location . ,numpy-pickle-location)
             (numpy-pickle-lower-bound . ,numpy-pickle-lower-bound)
             (use-numcl-arrays . ,use-numcl-arrays)))
    ;; to avoid development overhead, we will not bring these variables "out"
    (save-config)))

(defun save-config ()
  #.(format nil "Save to ~D from *CONFIG*" +py4cl2-config-path+)
  (let ((config-path (concatenate 'string
                                  (directory-namestring (asdf:component-pathname
                                                         (asdf:find-component
                                                          :py4cl2 "python-code")))
                                  ".config")))

    (with-open-file (f config-path :direction :output :if-exists :supersede
                       :if-does-not-exist :create)
      (cl-json:encode-json-alist *config* f))
    (format t "Configuration is saved to ~D.~%" config-path)))

(defun load-config ()
  #.(format nil "Load to *CONFIG* from ~D" +py4cl2-config-path+)
  (let ((config-path +py4cl2-config-path+)
        (cl-json:*json-symbols-package* *package*))
    (setq *config* (with-open-file (f config-path)
                     (cl-json:decode-json f)))))

(defun config-var (var)
  "Returns the value associated with VAR in *CONFIG*.
Configuration variables include (all in PY4CL2 package):

  - PYCMD: Path to the python binary to be used
  - NUMPY-PICKLE-LOCATION: PY4CL2 uses pickled files to transfer large arrays between lisp
 and python efficiently. These can have sizes exceeding 100MB. It is recommended that this
 be set to path on a ram-disk. See [this](https://unix.stackexchange.com/questions/66329/creating-a-ram-disk-on-linux) for
instructions on creating a ram-disk on linux-based systems.
  - NUMPY-PICKLE-LOWER-BOUND: The minimum size of the array for which PY4CL2 should use pickled files.
  - USE-NUMCL-ARRAYS: NUMCL uses displaced arrays. If this variable is T and the system PY4CL2+NUMCL is loaded, arrays returned by python process are passed through NUMCL:ASARRAY before returning them to the user."
  (cdr (assoc var *config*)))

(defun (setf config-var) (new-value var)
  "Sets the value of VAR to NEW-VALUE in *CONFIG*. For all but PYCMD, the values are saved to a configuration-file for persistence whenever they are changed. To persist PYCMD, call SAVE-CONFIG."
  (if (assoc var *config*)
      (setf (cdr (assoc var *config*)) new-value)
      (push (cons var new-value) *config*))
  ;; say, the user wants the python process to be project local
  (if (eq var 'pycmd)
      (format t "~&Call (SAVE-CONFIG) if you'd like to persist this value for PYCMD.
You will need to (PYSTOP) and (PYSTART) to use the new binary.~%")
      (save-config))
  (when (python-alive-p) (pycall "_py4cl_load_config")))

(defun py-cd (path)
  (pyexec "import os")
  (pycall "os.chdir" path))
