class Nokia{
    static int mic;
    static int cam;

    void setValue(){
        mic=10;
        cam=20;
    }
    void display(){
        System.out.println(mic);
        System.out.println(cam);

    }
}

public class ClasseAndObjects {
    public static void main(String[] args) {
        Nokia n1 = new Nokia();
        Nokia n2 = new Nokia();
        n1.display();
        n1.setValue();
        n1.display();
        n2.display();

    }
}
