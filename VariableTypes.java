class VariableTypes {

    // ===== Instance variable =====
    int instanceVar = 10;

    // ===== Static (class) variable =====
    static int staticVar = 20;

    void showVariables() {

        // ===== Local variable =====
        int localVar = 30;

        System.out.println("Local Variable      : " + localVar);
        System.out.println("Instance Variable   : " + instanceVar);
        System.out.println("Static Variable     : " + staticVar);
    }

    public static void main(String[] args) {

        VariableTypes obj1 = new VariableTypes();
        VariableTypes obj2 = new VariableTypes();

        obj1.showVariables();

        // Modify instance and static variables
        obj1.instanceVar = 100;
        VariableTypes.staticVar = 200;

        System.out.println("\nAfter modification:\n");

        obj2.showVariables();
    }
}
