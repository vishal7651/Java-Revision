import java.io.*;

class Student implements Serializable{
int id;
int rno;
transient String password;

Student(int id,int rno, String password){
    this.id=id;
    this.rno=rno;
    this.password=password;
}
}

public class SerializationTest{
public static void main(String[] args) throws Exception{

Student s = new Student(101, 21, "Vishal");

ObjectOutputStream os = new ObjectOutputStream(new FileOutputStream ("abc.txt"));

os.writeObject(s);

os.close();

System.out.println("Serialization Complete");

ObjectInputStream is = new ObjectInputStream(new FileInputStream ("abc.txt"));

s=(Student) is.readObject();

is.close();

System.out.println("deserialization Complete");
System.out.println("Id is : "+s.id+"Roll No is "+s.rno+" Password is "+s.password);
}
}



 

