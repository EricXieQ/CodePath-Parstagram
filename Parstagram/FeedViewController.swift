//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Eric Xie  on 3/7/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, MessageInputBarDelegate{

    @IBOutlet weak var tableView: UITableView!
    
    let commentBar = MessageInputBar()
    
    var posts = [PFObject]()
    var refreshControl: UIRefreshControl!
    var showCommentBar = false
    var selectorPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment here: "
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        // Do any additional setup after loading the view.
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
    }
    
    @objc func keyboardWillBeHidden(note: Notification){
        
        commentBar.inputTextView.text = nil
        showCommentBar = false
        becomeFirstResponder()
        
    }
    
    override var inputAccessoryView: UIView? {
        
        return commentBar
        
    }
    
    override var canBecomeFirstResponder: Bool{
        
        return showCommentBar
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        let query = PFQuery(className:"POSTS")
        query.includeKeys( ["author","comments","comments.author"] )
        query.limit = 30
        
        query.findObjectsInBackground { posts, error in
            if posts != nil {
                
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
        
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String){
        //Adding comment
        
        let comment = PFObject(className: "comments")
        
        comment["text"] = text
        comment["post"] = selectorPost
        comment["author"] = PFUser.current()!

        selectorPost.add(comment, forKey: "comments")
        selectorPost.saveInBackground { success, error in
            if success{

                print("Comment saved")

            }else{

                print("Error saving comment")

            }
        }
        
        tableView.reloadData()
        
        // remove comment
        commentBar.inputTextView.text = nil
        showCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row  == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            let user = post["author"] as! PFUser
            
            cell.usernameLabel.text = user.username
            cell.captionLabel.text = (post["captions"] as! String)
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!

            cell.photoView.af.setImage(withURL: url)
            
            return cell
            
        }else if indexPath.row <= comments.count{
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as! commentCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            
            return cell
            
        }else{
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "addCommentCell")!
            
            return cell
            
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post = posts[indexPath.section]
        
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            
            showCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectorPost = post
        }

    }
    
    
    @objc func onRefresh() {
        
        run(after: 2) {
           self.refreshControl.endRefreshing()
        }
       
    }
    
    func run(after wait: TimeInterval, closure: @escaping () -> Void) {
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: DispatchTime.now() + wait, execute: closure)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
//
//    func loadMorePosts(){
//
//        let query = PFQuery(className:"POSTS")
//        query.includeKey("author")
//        query.limit += 20
//
//        query.findObjectsInBackground { posts, error in
//            if posts != nil {
//
//                self.posts = posts!
//                self.tableView.reloadData()
//            }
//        }
//
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//
//        if indexPath.row + 1 == posts.count{
//            print(true)
//            loadMorePosts()
//        }
//    }
    
    @IBAction func Logout(_ sender: Any) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let LoginViewController = main.instantiateViewController(withIdentifier: "loginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
        
        delegate.window?.rootViewController = LoginViewController
    }
    
    
}
