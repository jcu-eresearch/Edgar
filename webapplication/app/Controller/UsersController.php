<?php
// app/Controller/UsersController.php
class UsersController extends AppController {
    public function login() {
        if ($this->Auth->login()) {
            $email = $this->Auth->user('email');
            $row = $this->User->findByEmail($email);
            if($row === False){
                # user has logged in for the first time, so make a new row
                # in the db for him/her
                $this->User->create(array('email' => $email));
                $this->User->save();
            }
            $this->redirect($this->Auth->redirect());
        } else {
            $this->Session->setFlash(__('Login failed.'));
        }
    }

    public function logout() {
        $this->redirect($this->Auth->logout());
    }
}
