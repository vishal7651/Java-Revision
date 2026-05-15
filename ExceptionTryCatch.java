public class ExceptionTryCatch {

    public void age(){
       
             int age=17;
            if(age < 18){
                throw new ArithmeticException("The Age is above 18");  //throw keyword
            }
        }
        public static void divide(int a, int b) throws ArithmeticException, ArrayIndexOutOfBoundsException{
            try{
                int c = a/b;
            System.out.println(c);
            int [] d = new int[3];
            d[5] = 20;
            System.out.println(d[5]);
            }catch (Exception e3){
                System.out.println(e3);
            }
        }
    public static void main(String[] args) {

        try {                                   //try block
            int a = 10 / 0;

            System.out.println(a);
        } catch (ArithmeticException e1) {      //catch block
            System.out.println(e1);
        }
        try {
            String b = null;
            System.out.println(b.length());
        } catch (NullPointerException e2) {
            System.out.println(e2);
        }
        try {

            int[] arr = new int[2];

            arr[5] = 10;

        } catch (ArithmeticException e) {

            System.out.println("Arithmetic");

        } catch (ArrayIndexOutOfBoundsException e) {

            System.out.println("Array Error");
        }
        finally{                                         // Finally 
            System.out.println("Finally block run");
        }
        try{
        ExceptionTryCatch c = new ExceptionTryCatch();
        c.age();
        }catch(Exception e4){
            System.out.println(e4);
        }

        divide(10, 2);
    }
}
