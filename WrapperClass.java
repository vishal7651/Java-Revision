public class WrapperClass {
    public static void main(String[] args) {
        int x= Integer.parseInt("123");   
        Integer x1=Integer.valueOf("1001101",2);
        int y = x1.intValue();

        System.out.println(x);
        System.out.println(y);

    }
}
