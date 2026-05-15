public class ExceptionTryCatch {
    public static void main(String[] args) {
        
  
    try{
        int a = 10/0;
        String b = null;
        System.out.println(b.length());
        // System.out.println(c);
    }catch(ArithmeticException e1){
        System.out.println(e1);
    }catch(NullPointerException e2){
        System.out.println(e2);
    }
      }
}
