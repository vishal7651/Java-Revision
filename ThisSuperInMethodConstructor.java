class Parent {

    int x = 10;

    Parent() {
        System.out.println("Parent no-arg constructor");
    }

    Parent(int x) {
        this.x = x;
        System.out.println("Parent parameterized constructor");
    }

    void show() {
        System.out.println("Parent show(): x = " + x);
    }
}

class Child extends Parent {

    int x = 20;

    Child() {
        this(50);              // calls Child(int)
        System.out.println("Child no-arg constructor");
    }

    Child(int value) {
        super(value);          // calls Parent(int)
        System.out.println("Child parameterized constructor");
    }

    void show() {
        super.show();          // calls Parent show()
        System.out.println("Child show(): x = " + this.x);
    }
}

public class ThisSuperInMethodConstructor {
    public static void main(String[] args) {

        Child c = new Child();
        c.show();
    }
}
