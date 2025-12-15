public class Construct {

    int x;
    int y;
    int z;

    Construct(){
        System.out.println("Default/No Args Constructor called");
    }

    Construct(int m, int n){
            x=m;
            y=n;
            System.out.println("Parameterized Constructor\n The value of x is: "+x+"and y: "+y);
            
    }
//Method Overloading 
     Construct(int m, int n, int p){
            x=m;
            y=n;
            z=p;
            System.out.println("Method Overloads\n The value of x is: "+x+"and y: "+y+"and z :"+z);

    }
    public static void main(String[] args) {
        Construct c1 = new Construct();
        Construct c2 = new Construct(12, 10);
        Construct c3 = new Construct(22, 33, 44);
    }
}