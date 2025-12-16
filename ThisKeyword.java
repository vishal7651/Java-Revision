class Animal {
    private int x;
    private int y;

    void setValue(int x, int y) {
        this.x = x;
        this.y = y;         //Differentiating instance and local variables
    }
    Animal(){
        this(10);   //Calling current class constructor 
        System.out.println("No arg Constructor");
    }

    Animal(int x){
        System.out.println("Parameterized Constructor" +x);
    }
    void show() {
        System.out.println(x);
        System.out.println(y);
    }
    Animal set(){
        return this;        //Returning current object
    }
}

public class ThisKeyword {
public static void main(String[] args) {
    Animal a = new Animal();
    a.setValue(12, 10);
    a.show();
}
}
