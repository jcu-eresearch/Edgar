<?php
// app/Controller/UsersController.php
class UsersController extends AppController {
    public function login() {
        if ($this->Auth->login()) {
            $this->redirect($this->Auth->redirect());
        } else {
            $this->Session->setFlash(__('Login failed.'));
        }
    }

    public function logout() {
        $this->redirect($this->Auth->logout());
    }
}
