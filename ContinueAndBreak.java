public class ContinueAndBreak {

    public static void main(String[] args) {

        System.out.println("Example of continue statement:");
        for (int i = 1; i <= 5; i++) {

            if (i == 3) {
                continue;   // skips iteration when i = 3
            }

            System.out.println("i = " + i);
        }

        System.out.println("\nExample of break statement:");
        for (int i = 1; i <= 5; i++) {

            if (i == 4) {
                break;      // exits loop when i = 4
            }

            System.out.println("i = " + i);
        }
    }
}
