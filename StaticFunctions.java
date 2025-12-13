public class StaticFunctions {

    static void run(){
        System.out.println("Run Function");
    }

    void walk(){
        System.out.println("Walk Function");
    }
    public static void main(String[] args) {
        run();
        StaticFunctions s1= new StaticFunctions();
        s1.walk();
    }
}
