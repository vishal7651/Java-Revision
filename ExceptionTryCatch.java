public class ExceptionTryCatch {
    public static void main(String[] args) {

        try {
            int a = 10 / 0;

            // System.out.println(c);
        } catch (ArithmeticException e1) {
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
    }
}
