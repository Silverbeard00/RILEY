(defpackage :riley
  (:use :cl
	:cl-who
	:cl-pass
	:hunchentoot
	:parenscript))
;;;All predicted data objects neededers

(defclass show ()
  ((contact-name :initarg :contact-name
		 :accessor show-contact-name)
   (phone-number :initarg :phone-number
		 :accessor show-phone-number)
   (order-amount :initarg :order-amount
		 :initform 0
		 :accessor show-order-amount)
   (list-of-invoices :initarg :list-of-invoices
		     :initform '()
		     :accessor list-of-invoices)
   (name :initarg :name
	 :accessor show-name)))

(defun make-show (&key contact-name-t phone-number-t
		    order-amount-t list-of-invoices-t
		    name-t )
  (make-instance 'show
		 :name name-t
		 :contact-name contact-name-t
		 :phone-number phone-number-t
		 :order-amount order-amount-t
		 :list-of-invoices list-of-invoices-t))
(defclass invoice ()
  ((id-num :initarg :id-num
	      :accessor invoice-id-num)
   (set-name :initarg :set-name
	     :accessor invoice-set-name)
   (date-out :initarg :date
	     :initform 0
	     :accessor invoice-date-out)
   (show-name :initarg :show-name
	      :accessor show-name)
   (contact-name :initarg :contact-name
		 :accessor invoice-contact-name)
   (check-in-accounting :initarg :check-in-accounting
			:accessor invoice-check-in-accounting)
   (item-list :initarg :itemlist
	      :accessor invoice-item-list)
   (pdf-location :initarg :pdf-location
		 :accessor invoice-pdf-location)))

(defclass check-in ()
  ((date :initarg :date
	 :accessor date)
   (invoice-refer :initarg :invoice-refer
		  :accessor check-in-invoice-refer)
   (checked-by :initarg :checked-by
	       :accessor check-in-checked-by)
   (show-name :initarg :show-name
	      :accessor check-in-show-name)
   (checks :initarg :checks
	   :accessor check-in-checks)))

(defclass item ()
  ((price :initarg :price
	  :accessor item-price)
   (quantity :initarg :quantity
	     :accessor item-quantity)
   (description :initarg :description
		:accessor item-description)
   (invoices-on :initarg :invoices-on
		:accessor item-invoices-on)
   (shows-on :initarg :shows-on
	     :accessor item-shows-on)))

(defclass user ()
  ((name :initarg :name
	 :accessor user-name)
   (rank :initarg :rank
	 :accessor user-rank)
   (password :initarg :password
	     :accessor user-password)
   (shows-checked :initarg :shows-checked
		  :accessor user-shows-checked)
   (invoice-history :initarg :invoice-history
		    :accessor user-invoice-history)
   (points :initarg :points
	   :accessor user-points)
   (messages :initarg :messages
	     :accessor user-messages)
   (status :initarg :status
	   :accessor user-status)))

(defclass message ()
  ((sender :initarg :sender
	   :accessor message-sender)
   (recipient :initarg :recipient
	      :accessor message-recipient)
   (date :initarg :date
	 :accessor message-date)
   (content :initarg :content
	    :accessor message-content)
   (reply :initarg :reply
	  :accessor message-reply)
   (read-date :initarg :read-date
	 :accessor message-read-date)
   (read-on :initarg :read-on
	    :accessor message-read-on)
   (private :initarg :private
	    :accessor message-private)
   (show-name :initarg :show-name
	      :accessor message-show-name)
   (invoice-name :initarg :invoice-name
		 :accessor message-invoice-name)
   (item-name :initarg :item-name
	      :accessor message-item-name)))

(defclass dashboard ()
    ((posts :initarg :posts
	    :accessor dashboard-posts)
     (current-date :initarg :current-date
		   :accessor dashboard-current-date)))
;;; Data
(defvar *global-invoice-id* 0)
(defvar *current-show-list* '())

(defun find-show-name (name data-lst)
  (find name data-lst :test #'string-equal
	:key #'show-name))

(defun add-show (show-obj)
  (push (make-instance 'show
		       :name (show-name show-obj)
		       :contact-name (show-contact-name show-obj)
		       :phone-number (show-phone-number show-obj)
		       :order-amount (show-order-amount show-obj)
		       :list-of-invoices (list-of-invoices show-obj))  *current-show-list* ))

(defvar *users* '())

(defun find-user (username)
  (find username *users* :test #'string-equal
	:key #'user-name))

(defun register-user (&key username password)
  (push (make-instance 'user
		       :name username
		       :password password
		       :rank "user")
	*users*))

(defvar *current-message-list* '())
(defun find-global-messages ()
  (remove-if-not (lambda (x)
		   (string= "global" (message-recipient x)))
		 *current-message-list*))

(defun register-message (&key sender recipient
			   date content
			   reply read-date
			   read-on private
			   show-name
			   invoice-name
			   item-name)
  (push (make-instance 'message
		       :sender sender
		       :recipient recipient
		       :reply reply
		       :date date
		       :content content
		       :read-date read-date
		       :read-on read-on
		       :private private
		       :show-name show-name
		       :invoice-name invoice-name
		       :item-name item-name)
	*current-message-list*))
(defvar *global-invoice-list* '())
(defun find-invoice-from-message (mess)
  (let ((setname (first (message-invoice-name mess)))
	(showname (second (message-invoice-name mess))))
    (first (remove-if-not (lambda (x)
		     (and (string= setname (invoice-set-name x))
			  (string= showname (show-name x))))
		   *global-invoice-list*))))



			 


(defun find-invoice (invoicename)
  (find invoicename *global-invoice-list* :test #'string-equal
	:key #'show-name))

(defun register-invoice (&key id-num
			   set-name
			   show-name
			   contact-name)
  (push (make-instance 'invoice
		       :id-num id-num
		       :set-name set-name
		       :show-name show-name
		       
		       :contact-name contact-name) *global-invoice-list*))
;;; Webserver functions and scaffolding
(setf (html-mode) :html5)

(defun start-server (port)
  (start (make-instance 'easy-acceptor :port port)))

(defmacro standard-page ((&key title) &body body)
  `(with-html-output-to-string
       (*standard-output* nil :prologue t :indent t)
     (:html :lang "en"
	    (:head
	     (:link :rel "stylesheet"
		    :type "text/css"
		    :href "css/bootstrap.css")
	     (:title ,title)
	     (:link :type "text/css"
		    :rel "stylesheet"
		    :href "css/bootstrap-theme.css")
	     (:link :type "text/css"
		    :rel "stylesheet"
		    :href "css/style.css"))
	    (:body
	    
	     ,@body))))
(defvar *global-invoice-list* '())

;;; Standard Page Macros

(defmacro standard-navbar ()
  `(with-html-output (*standard-output* nil :indent t)
     (:nav :class "navbar navbar-default" :role "navigation"
	   (:div :class "container-fluid"
		 (:div :class "navbar-header"
		       (:button :type "button"
				:class "navbar-toggle collapsed"
				:data-toggle "collapsed"
				:data-target "#collapsible"
				(:span :class "sr-only" "Toggle navigation")
				(:span :class "icon-bar")
				(:span :class "icon-bar")))
		 (:div :class "collapse navbar-collapse"
		       :id "collapsible"
		       (:ul :class "nav navbar-nav"
			    (:li (:a :href "/dashboard" "Timeline"))
			    (:li (:a :href (concatenate 'string "/profile/" (cookie-in "current-user"))  "Profile"))
			    (:li (:a :href "/write-order" "Write Order")))
		       (:ul :class "nav navbar-nav navbar-right"
			    (:li (:a :href "/signout" "Sign out"))))))))

(defmacro standard-dashboard (&key messages)
  `(with-html-output (*standard-output* nil :indent t)
     (:div :class "panel panel-default"
	   (:div :class "panel-heading user-brief"
		 (:h1 "Dashboard")
		 (:form :role "form"
			:action "/addmessage"
			:method "post"
			:class "form-inline"
			(:div :class "form-group"
			      (:label :class "sr-only" :for "tweet" "Say Something")
			      (:input :type "text" :class "form-control"
				      :id "message" :name "message"
				      :placeholder "Post a message")
			      (:button :type "Submit Message" :class "btn btn-default" "Message"))))
	   (:div :class "panel-body"
		 ,messages))))

(defmacro standard-global-messages ()
  `(with-html-output (*standard-output* nil :indent t)
     (dolist (messages (find-global-messages)) 
     (htm (:div :class "media alert alert-info"
	   (:div :class "media-left"
		 (:a :class "pull-left" :href (concatenate 'string "/profile/" (message-sender messages))))
	   (:div :class "media-body"
		 (:h4 :class "media-heading"
		      (:a :href (concatenate 'string "/profile/" (message-sender messages))
			  (fmt "~A" (escape-string (message-sender messages)))))
		 
		 (fmt "~A" (escape-string (message-content messages))))
	   (if (find-invoice-from-message messages)
	       (htm
		(:div :class "media-right"
		      (:form :action "/setthemcookies"
			     :method "POST"
			     (:input :type "hidden" :name "showname" :value (show-name (find-invoice-from-message messages)))
			     (:input :type "hidden" :name "setname" :value (invoice-set-name (find-invoice-from-message messages)))
			     (:input :type "hidden" :name "contact" :value (invoice-contact-name (find-invoice-from-message messages)))
		 (:button :type "submit" :class "btn btn-default" "Write Order"))))))))))

(defmacro standard-order-intro ()
  `(with-html-output (*standard-output* nil :indent t)
     (:div :class "panel panel-default"
	   (:div :class "panel-body" (:form :class "form-inline"
	    :action "/createInvoice"
	    :method "POST"
	    :id "New-invoice-form"
	    (:div :class "form-group"
		  (:label :for "inputShow" "Show")
		  (:input :type "text" :class "form-control" :id "inputShowname"
			  :placeholder "Showname" :name "inputShowname"))
	    (:div :class "form-group"
		  (:label :for "inputSet" "Set")
		  (:input :type "text" :class "form-control" :id "inputSetname"
			  :placeholder "Set Name" :name "inputSetname"))
	    (:div :class "form-group"
		  (:label :for "inputContact" "Contact Name")
		  (:input :type "text" :class "form-control" :id "inputContact"
			  :placeholder "Contact Name" :name "inputContact"))
	    (:button :type "submit" :class "btn btn-default" "Write Show Order"))))))

(defmacro standard-picture-upload ()
  `(with-html-output (*standard-output* nil :indent t)
     (:div :class "panel panel-default"
	   (:div :class "panel-body"
		 (:form :action "/displayimagegot"
			:class "form-inline"
			:method "POST"
			:enctype "multipart/form-data"
			:id "new-picture-upload"
			(:div :class "form-group"
			      (:input
			       :multiple "multiple"
			       :id "picture-batch"
			       :name "picture-batch"
			       :type "file"
			       
				      :name "img"
				      )
			      (:input :type "submit")))))))
(defmacro standard-invoice-writing (&key show set contact)
  `(with-html-output (*standard-output* nil :indent t)
     (:div :class "panel panel-default"
	   (:div :class "panel-body"
		 (:ul :class "list-group"
		      (:li :class "list-group-item list-group-item-success" ,show)
		      (:li :class "list-group-item list-group-item-danger" ,set)
		      (:li :class "list-group-item list-group-item-success" ,contact))))))

(define-easy-handler (createInvoice :uri "/createInvoice") ()
  (let ((showname (hunchentoot:post-parameter "inputShowname"))
	(setname (hunchentoot:post-parameter "inputSetname"))
	(contact (hunchentoot:post-parameter "inputContact")))
    (register-invoice :id-num (+ *global-invoice-id* 1)
		      :set-name setname
		      :show-name showname
		      :contact-name contact)
    (set-cookie "current-invoice" :value  *global-invoice-id*)
  (register-message :sender "Global Messages" :recipient "global"
		    :content (concatenate 'string "An order has been started for " showname
					   " for set " setname
					   " ordered by " contact )
		    :invoice-name (list setname showname contact *global-invoice-id*)))
  (redirect "/dashboard"))
		      
(define-easy-handler (write-order :uri "/write-order") ()
  (standard-page (:title "Write Order")
    (standard-navbar)
    (standard-order-intro)))

(define-easy-handler (addmessage :uri "/addmessage") ()
  (let ((username (cookie-in "current-user"))
	(message (hunchentoot:post-parameter "message")))
    (register-message :sender username
		      :recipient "global"
		      :content message))
  (redirect "/dashboard"))

(define-easy-handler (dashboard :uri "/dashboard") ()
  (let ((username (cookie-in "current-user")))
    (if (not (or (string= username "login") (string= username "")))
  (standard-page (:title "Dashboard")
    (standard-navbar)
    (standard-dashboard :messages (standard-global-messages)))
  (redirect "/login"))))

(define-easy-handler (displayimagegot :uri "/displayimagegot") ()
  (let ((whatever (loop for post-parameter in (hunchentoot:post-parameters*)
		     if (equal (car post-parameter) "picture-batch")
				    collect post-parameter)))
    (standard-page (:title "Picture Batch")
      (standard-navbar)
      (mapc #'(lambda (x)
		(format t "~A ~A ~A ~A <br>"  (car x)
			(second x)
			(third x)
			(fourth x)))
		     
	    whatever))))

(define-easy-handler (setthemcookies :uri "/setthemcookies") ()
  (standard-page (:title "Set Them Cookies")
    (standard-navbar)
    (standard-invoice-writing :show  (fmt "Showname: ~A" (escape-string (hunchentoot:post-parameter "showname")))
			      :set (fmt "Setname: ~A" (escape-string (hunchentoot:post-parameter "setname")))
			      :contact (fmt "Contact: ~A" (escape-string (hunchentoot:post-parameter "contact"))))
    (standard-picture-upload)))

(define-easy-handler (signout :uri "/signout") ()
  (set-cookie "current-user" :value "login")
  (redirect "/login"))

(define-easy-handler (profilelogin :uri "/profilelogin") ()
  (redirect "/login"))
(define-easy-handler (home :uri "/") ()
  (standard-page (:title "RILEY Inventory System")
    (redirect "/login")))

(define-easy-handler (check-login :uri "/check-login") ()
  (let
      ((username (hunchentoot:post-parameter "username"))
       (password (hunchentoot:post-parameter "password")))
    (cond ((cl-pass:check-password password (user-password (find-user username)))
	   (set-cookie "current-user" :value username)
	   (redirect "/dashboard"))
	  (t
	   (redirect "/login")))))

(define-easy-handler (createshow :uri "/createshow") ()
  (standard-page (:title "CREATE SHOW")
    (:div :id "form"
	  (:form :action "/addshow"
		 :method "POST"
		 :id "commentform"
		 (:input :type "text"
			 :placeholder "Show Name"
			 :name "name"
			 :id "name")
		 (:br)
		 (:input :type "text"
			 :placeholder "Contact Name"
			 :name "contact-name"
			 :id "contact-name")
		 (:br)
		 (:input :type "text"
			 :placeholder "Phone Number"
			 :name "phone-number"
			 :id "phone-number")
		 (:br)
		 (:button :type "submit"
			  :class "btn btn-primary"
			  "Create Show")))))

(define-easy-handler (addshow :uri "/addshow") ()
  (add-show (make-instance 'show
			   :name (hunchentoot:post-parameter "name")
			   :contact-name (hunchentoot:post-parameter "contact-name")
			   :phone-number (hunchentoot:post-parameter "phone-number")))
  (redirect "/"))

(define-easy-handler (adduser :uri "/adduser") ()
  (let ((username (hunchentoot:post-parameter "username"))
	(password (hunchentoot:post-parameter "password"))
	(password-repeat (hunchentoot:post-parameter "password-repeat")))
    (if (and (string= password password-repeat)
	     (not (find-user username)))
	(and (register-user :username username
			    :password (cl-pass:hash password))
	     (redirect "/login"))
	(redirect "/badpassword"))))

(define-easy-handler (login :uri "/login") ()
  (standard-page (:title "Login")
    (:div :id "landing"
	  (:div :class "panel panel-default"
	  :id "welcome-panel"
	  (:div :class "panel-heading"
		(:h1 "Welcome to the RILEY Inventory System"))
	  (:div :class "panel-body"
		(:div :class "row"
		(:div :class "col-md-6"
		     
		(:div :id "form"
	  (:form :action "/adduser"
		 :method "POST"
		 :id "commentform"
		 (:input :type "text"
			 :placeholder "Username"
			 :name "username"
			 :id "username")
		 (:br)
		 (:input :type "password"
			 :placeholder "Password"
			 :name "password"
			 :id "password")
		 (:br)
		 (:input :type "password"
			 :placeholder "Repeat Password"
			 :name "password-repeat"
			 :id "password-repeat")
		 (:br)
		 (:button :type "submit"
			  :class "btn btn-primary"
			  "Create Account"))))
    (:br)
    (:div :class "col-md-6"
	  (:div :id "form"
	  (:form :action "/check-login"
		 :method "POST"
		 :id "commentform"
		 (:input :type "text"
			 :placeholder "Username"
			 :name "username"
			 :id "username")
		 (:br)
		 (:input :type "password"
			 :placeholder "Password"
			 :name "password"
			 :id "password")
		 (:br)
		 (:button :type "submit"
			  :class "btn btn-primary"
			  "Login"))))))))))
