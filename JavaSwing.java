import javax.swing.*;
import java.awt.*;

public class JavaSwing extends JFrame{

    JavaSwing(String s1){
        super(s1);
    }

  JLabel l1= new JLabel("Welcome");
  JTextArea t1 = new JTextArea("Username");
  JTextArea t2 = new JTextArea("Password");
  JButton b1 = new JButton("Add");


    void setComponents(){
                this.setLayout(null);


          t1.setBounds(300, 300, 200, 150);
    t2.setBounds(400, 400, 200, 150);
    b1.setBounds(500, 500, 200, 150);
    this.add(t1);
    this.add(t2);
    this.add(b1);
    this.setVisible(true);
  

    }

    public static void main(String[] args) {

        JavaSwing jw = new JavaSwing("Calculator");
        jw.setComponents();
        
    }
    
}