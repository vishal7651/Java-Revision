public class WrapperClass {
    public static void main(String[] args) {
        int x= Integer.parseInt("123");  
        System.out.println(x);
        
        Integer x1=Integer.valueOf("1001101",2);
        System.out.println(x1);
        int y = x1.intValue();

        System.out.println(y);

        

    }
}
