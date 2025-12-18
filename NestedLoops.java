public class NestedLoops {

    public static void main(String[] args) {

        // ===== 1. Nested loop =====
        System.out.println("Nested Loop (Pattern):");
        for (int i = 1; i <= 3; i++) {
            for (int j = 1; j <= 3; j++) {
                System.out.print("* ");
            }
            System.out.println();
        }

        // ===== 2. Enhanced for loop =====
        System.out.println("\nEnhanced For Loop:");
        int[] numbers = {10, 20, 30, 40};

        for (int num : numbers) {
            System.out.println(num);
        }
    }
}
